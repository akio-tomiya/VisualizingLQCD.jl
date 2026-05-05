FROM texlive/texlive:latest
WORKDIR /work
COPY . /work
RUN apt-get update && apt-get install -y --no-install-recommends make && rm -rf /var/lib/apt/lists/*
CMD ["make"]
