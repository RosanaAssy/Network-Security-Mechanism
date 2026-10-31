# Protected service: OpenSSH (port 22) + BusyBox web server (port 80)
FROM alpine:3.22.6

# Fake test account - NOT a real credential
RUN apk add --no-cache openssh busybox-extras \
 && ssh-keygen -A \
 && adduser -D student \
 && echo 'student:sunshine' | chpasswd \
 && printf 'PasswordAuthentication yes\nPerSourcePenalties no\nMaxAuthTries 1\n' >> /etc/ssh/sshd_config

COPY index.html /www/index.html

EXPOSE 22 80
CMD ["sh", "-c", "httpd -p 80 -h /www && exec /usr/sbin/sshd -D -e"]
