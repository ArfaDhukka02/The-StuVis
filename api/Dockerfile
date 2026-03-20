#installing base image
FROM python:3.9-slim
#creating a working directory all commands run here
WORKDIR /app

#copy all the list of dependencies that are required 
COPY requirements.txt .

#install all the dependencies
RUN pip install -r requirements.txt

#copy all the code to images
COPY app.py .

#documents that the port listens at 5000
EXPOSE 5000

#and finally run the app when container starts

CMD ["python", "app.py"]
