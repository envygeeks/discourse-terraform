templates:
  - "templates/web.template.yml"
  - "templates/web.ratelimited.template.yml"
expose:
  - "80:80"
env:
  LANG: en_US.UTF-8
  DISCOURSE_SMTP_PORT: "${discourse_smtp_port}"
  DISCOURSE_REDIS_HOST: "${discourse_redis_host}"
  DISCOURSE_SMTP_ADDRESS: "${discourse_smtp_address}"
  DISCOURSE_DEVELOPER_EMAILS: "${discourse_developer_emails}"
  DISCOURSE_DB_PASSWORD: "${discourse_postgres_password}"
  DISCOURSE_DB_USERNAME: "${discourse_postgres_username}"
  DISCOURSE_SMTP_USER_NAME: "${discourse_smtp_username}"
  DISCOURSE_SMTP_PASSWORD: "${discourse_smtp_password}"
  DISCOURSE_DB_HOST: "${discourse_postgres_host}"
  DISCOURSE_REDIS_PORT: "${discourse_redis_port}"
  DISCOURSE_HOSTNAME: "${discourse_hostname}"
# --
# This isn't very volatile, we should probably
# Store this data on an EFS, this way the servers can
# be volatile with static data.
# --
volumes:
  - volume:
      host: /opt/discourse/shared/web
      guest: /shared
  - volume:
      host: /opt/discourse/shared/web/log/var-log
      guest: /var/log
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/discourse/docker_manager.git
