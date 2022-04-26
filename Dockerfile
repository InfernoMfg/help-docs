FROM ntno/ubuntu-build-base:0.0.11

WORKDIR /usr/src/

COPY . .

RUN pip install -r /usr/src/requirements.txt

EXPOSE 7000

CMD ["mkdocs", "serve", "-v", "--dev-addr=0.0.0.0:7000"]
