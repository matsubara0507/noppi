#!/usr/bin/env python3

import tweepy
import os
import json
from dotenv import load_dotenv

load_dotenv("./.env")

consumer_key = os.environ.get("CONSUMER_KEY")
consumer_secret = os.environ.get("CONSUMER_SECRET")
access_token = os.environ.get("ACCESS_TOKEN")
access_token_secret = os.environ.get("ACCESS_TOKEN_SECRET")

auth = tweepy.OAuthHandler(consumer_key, consumer_secret)
auth.set_access_token(access_token, access_token_secret)

api = tweepy.API(auth)

retry = True
retry_cnt = 3
result = []
max_id = None
while retry:
    status = api.user_timeline(screen_name="@IPPONGP", count=200, max_id=max_id)
    result += list(filter(lambda stat: 'このお題の回答をつぶやいてください' in stat.text, status))
    retry_cnt -= 1
    retry = retry_cnt > 0 and len(status) > 0
    if retry:
        max_id = status.max_id - 1

def encode(stat):
    return {
        "enable": True,
        "url": f"https://twitter.com/IPPONGP/status/{stat.id_str}",
        "image": stat.extended_entities['media'][0]['media_url_https']
    }

dump = list(map(lambda stat: encode(stat), result))
print(json.dumps(dump))
