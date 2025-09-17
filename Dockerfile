FROM python:3.9

WORKDIR /code

COPY /api/requirements.txt /code/requirements.txt

RUN pip install -r /code/requirements.txt

COPY ./api /code/app

CMD ["fastapi", "run", "app/main.py", "--port", "80"]