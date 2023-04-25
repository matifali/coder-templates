FROM ghcr.io/coder/code-server:latest
ENV CODER_ENTRYPOINT=
# ENTRYPOINT [ "/bin/sh", "-c", "exec /bin/sh <<<"$CODER_ENTRYPOINT" ]
# ENTRYPOINT [ "${CODER_ENTRYPOINT}" ]
# ENTRYPOINT "'$CODER_ENTRYPOINT'"
# Create a file with the contents of $CODER_ENTRYPOINT and execute it with /bin/sh
# RUN 
# ENTRYPOINT [ "echo $CODER_ENTRYPOINT > /tmp/entrypoint.sh && chmod +x /tmp/entrypoint.sh && /tmp/entrypoint.sh" ]
# ENTRYPOINT []
# # Write the contents of $CODER_ENTRYPOINT to a file and execute it with /bin/sh
# CMD [ "echo $CODER_ENTRYPOINT > /tmp/entrypoint.sh && /bin/sh /tmp/entrypoint.sh" ]
ENTRYPOINT [ "echo $CODER_ENTRYPOINT | /bin/sh" ]