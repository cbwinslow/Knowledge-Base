FROM python:3.11-slim
WORKDIR /agent
RUN pip install requests
COPY agent.py .
CMD ["python","agent.py"]
