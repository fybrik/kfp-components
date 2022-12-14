FROM python:3.7
COPY ./train.py .
COPY requirements.txt .
RUN python -m pip install -r \
    requirements.txt --quiet --no-cache-dir \
    && rm -f requirements.txt
CMD ["python3", "train.py"]
