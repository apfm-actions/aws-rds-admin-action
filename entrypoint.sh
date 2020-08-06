#!/bin/sh
set -e

error() { echo "error: $*" >&2; }
die() { error "$*"; exit 1; }
toupper() { echo "$*" | tr '[a-z]' '[A-Z]'; }
tolower() { echo "$*" | tr '[A-Z]' '[a-z]'; }

aws_account_id() { aws --output=json sts get-caller-identity | jq -rc '.["Account"]'; }
aws_region() {
	if test -z "${INPUT_REGION}"; then
		aws configure list | awk '$1 ~ /^region$/{print$2}'
	else
		echo "${INPUT_REGION}"
	fi
}
aws_policy_arn()
{
	test -n "${1}" || return 0
	case "${1}" in
	(arn:aws:*)	echo "${1}";;
	(*)		echo "arn:aws:iam::$(aws_account_id):policy/${1}"
	esac
}
aws_role_arn()
{
	test -n "${1}" || return 0
	case "${1}" in
	(arn:aws:*)	echo "${1}";;
	(*)		echo "arn:aws:iam::$(aws_account_id):role/${1}"
	esac
}


if ! test -z "${INPUT_AWS_ROLE_ARN}"; then
	set --
	if ! test -z "${INPUT_AWS_EXTERNAL_ID}"; then
		set -- --external-id "${INPUT_AWS_EXTERNAL_ID}"
	fi
	AWS_ACCESS_JSON="$(aws sts assume-role "${@}" \
		--role-arn "${INPUT_AWS_ROLE_ARN}" \
		--role-session-name 'aws-ecs-exec-action')"

	export AWS_ACCESS_KEY_ID="$(echo "${AWS_ACCESS_JSON}"|jq -r '.Credentials.AccessKeyId')"
	export AWS_SECRET_ACCESS_KEY="$(echo "${AWS_ACCESS_JSON}"|jq -r '.Credentials.SecretAccessKey')"
	export AWS_SESSION_TOKEN="$(echo "${AWS_ACCESS_JSON}"|jq -r '.Credentials.SessionToken')"
fi

DEBUG=
if test "${INPUT_DEBUG}" = 'true'; then
	DEBUG='--debug'
        set -x
fi

WAIT=
! "${INPUT_WAIT}" || WAIT='--wait'

# Common Variables
export DB_NAME=${DB_NAME:?'DB_NAME variable missing.'}
export SKIP_DB_CREATION=${SKIP_DB_CREATION:-'false'}
export DB_USER=${DB_USER:-'root'}
export DB_RANDOM_PASSWORD=$(date +%s | sha256sum | base64 | head -c 16)
export DB_NEW_USER=${DB_NEW_USER:-"${DB_NAME}_user"}

if test "${ENGINE}" = 'mysql'; then
    export DB_CLUSTER=${DB_CLUSTER:-'default-aurora-mysql'}
    export DB_PASSWORD=$(aws ssm get-parameter --name "/${DB_CLUSTER}/password/master" --with-decryption | jq -r '.Parameter.Value')
    export DB_HOST=${DB_HOST:-$(aws rds describe-db-clusters --db-cluster-identifier default-aurora-mysql | jq -r '.DBClusters[].Endpoint'))}
	export DB_HOST_READER=${DB_HOST_READER:-$(aws rds describe-db-clusters --db-cluster-identifier default-aurora-mysql | jq -r '.DBClusters[].ReaderEndpoint'))}
    export DB_PORT='3306'
    if test "${SKIP_DB_CREATION}" = 'false'
        mycli -h $DB_HOST -u $DB_USER -p$DB_PASS -P $DB_PORT -e "CREATE DATABASE $DB_NAME"
    fi
    mycli -h $DB_HOST -u $DB_USER -p$DB_PASS -P $DB_PORT -e "CREATE USER '$DB_NEW_USER'@'*' IDENTIFIED BY PASSWORD PASSWORD('$DB_RANDOM_PASSWORD')"
    mycli -h $DB_HOST -u $DB_USER -p$DB_PASS -P $DB_PORT -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO myuser"
    aws ssm put-parameter --type SecureString --name "/default-aurora-mysql/password/$DB_NAME" --value "$DB_RANDOM_PASSWORD"
    #aws ssm put-parameter --type SecureString --name "/default-aurora-mysql/connection/$DB_NAME" --value  "postgresql://${DB_NEW_USER}:${DB_RANDOM_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
elif test "${ENGINE}" = 'postgresql'; then
    export DB_CLUSTER=${DB_CLUSTER:-'default-aurora-postgresql'}
    export PGPASSWORD=$(aws ssm get-parameter --name "/${DB_CLUSTER}/password/master" --with-decryption | jq -r '.Parameter.Value')
    export DB_HOST=${DB_HOST:-$(aws rds describe-db-clusters --db-cluster-identifier ${DB_CLUSTER} | jq -r '.DBClusters[].Endpoint')}
    export DB_PORT='5432'
    if test "${SKIP_DB_CREATION}" = 'false'
        psql -U $DB_USER -h $DB_HOST postgres -c "CREATE DATABASE $DB_NAME"
    fi    
    psql -U $DB_USER -h $DB_HOST postgres -c "CREATE USER ${DB_NEW_USER} WITH ENCRYPTED PASSWORD '$DB_RANDOM_PASSWORD'"
    psql -U $DB_USER -h $DB_HOST postgres -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_NEW_USER"
    aws ssm put-parameter --type SecureString --name "/${DB_CLUSTER}/password/$DB_NAME" --value "$DB_RANDOM_PASSWORD"
    aws ssm put-parameter --type SecureString --name "/${DB_CLUSTER}/connection/writer/$DB_NAME" --value  "postgresql://${DB_NEW_USER}:${DB_RANDOM_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
	aws ssm put-parameter --type SecureString --name "/${DB_CLUSTER}/connection/reader/$DB_NAME" --value  "postgresql://${DB_NEW_USER}:${DB_RANDOM_PASSWORD}@${DB_HOST_READER}:${DB_PORT}/${DB_NAME}"
else
    echo "ENGINE variable incorrect."
    return 1
fi

