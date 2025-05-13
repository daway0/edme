import jwt
import datetime

def generate_token(username, expire_seconds=3600):
        SECRET_KEY = 'django-insecure-#kkatg$g5w^93x$r8a@2bo*c8scivp8&k0it4_bvjw4197b1go'
        payload = {
            "username": username,
            "exp": datetime.datetime.utcnow() + datetime.timedelta(seconds=expire_seconds)
        }
        token = jwt.encode(payload, SECRET_KEY, algorithm="HS256")
        return token if isinstance(token, str) else token.decode("utf-8")