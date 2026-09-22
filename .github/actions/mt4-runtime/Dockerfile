FROM docker.io/mhriemers/metatrader-4@sha256:ed6c3abb2188ac178f183e30bd03cb85c7f2bf8abebfdffa70c070ff2fb1ad74
COPY entrypoint.sh /p05-runtime.sh
RUN chmod +x /p05-runtime.sh
ENTRYPOINT ["/p05-runtime.sh"]
