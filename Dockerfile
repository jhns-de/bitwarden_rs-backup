FROM alpine:latest

RUN addgroup -S app && adduser -S -G app app

RUN apk add --no-cache \
    sqlite \
    busybox-suid \
    su-exec \
    rsync

RUN wget -O /opt/duplicacy https://github.com/gilbertchen/duplicacy/releases/download/v2.7.2/duplicacy_linux_x64_2.7.2 && chmod 777 /opt/duplicacy

ENV DB_FILE /data/db.sqlite3
ENV BACKUP_FILE /backup/backup.sqlite3
ENV BACKUP_FILE_PERMISSIONS 700
ENV CRON_TIME "0 3 * * *"
ENV TIMESTAMP false
ENV UID 100
ENV GID 100
ENV CRONFILE /etc/crontabs/root
ENV LOGFILE /app/log/backup.log
ENV DELETE_AFTER 0
ENV DIRECT_BACKUP false

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY backup.sh /app/

RUN mkdir /app/log/ \
    && chown -R app:app /app/ \
    && chmod -R 777 /app/ \
    && chmod +x /usr/local/bin/entrypoint.sh
#    && echo "\$CRON_TIME \$BACKUP_CMD >> \$LOGFILE 2>&1" | crontab -

ENTRYPOINT ["entrypoint.sh"]
