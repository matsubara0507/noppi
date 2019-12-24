FROM python:3.8.1-slim

ENV TWEEPY_VERSION 3.8.0
ENV DOTENV_VERSION 0.10.3
RUN pip install \
    tweepy==$TWEEPY_VERSION \
    python-dotenv==$DOTENV_VERSION

COPY entrypoint.py /entrypoint.py

ENTRYPOINT ["/entrypoint.py"]
