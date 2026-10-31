# Benign client: normal web browsing and normal SSH logins
FROM alpine:3.22.6

RUN apk add --no-cache curl openssh-client sshpass bash

COPY benign.sh /benign.sh
RUN chmod +x /benign.sh

CMD ["/benign.sh"]
