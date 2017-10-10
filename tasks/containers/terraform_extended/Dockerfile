FROM hashicorp/terraform:light

RUN apk add bash python \
  && bash -c "bash <(curl https://sdk.cloud.google.com) --disable-prompts" \
  && echo 'source /root/google-cloud-sdk/path.bash.inc' >> ~/.bash_profile

ENTRYPOINT ["/bin/bash", "-l"]
