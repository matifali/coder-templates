FROM ghcr.io/coder/code-server:latest
USER 0
RUN curl -s https://raw.githubusercontent.com/coder/coder/main/provisionersdk/scripts/bootstrap_linux.sh > /opt/entrypoint.sh && chmod +x /opt/entrypoint.sh
USER 1000
ENTRYPOINT []
CMD [ "/opt/entrypoint.sh" ]