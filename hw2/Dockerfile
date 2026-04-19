FROM python:3.14-slim

WORKDIR /app
COPY app.py requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

RUN mkdir -p /app/logs
EXPOSE 8080

CMD ["python", "app.py"]