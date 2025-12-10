FROM node:lts-alpine

# install curl and unzip
RUN apk add --no-cache curl unzip

# Create a non-root user and group
RUN addgroup -S wis2box-webapp && adduser -S wis2box-webapp -G wis2box-webapp

# Set the working directory inside the container
WORKDIR /wis2box-webapp

# copy both 'package.json' and 'package-lock.json' (if available)
COPY package*.json ./

# install project dependencies
RUN npm install

# copy project files and folders to the current working directory
COPY . .

# Make scripts executable
RUN chmod +x /wis2box-webapp/docker/entrypoint.sh \
    && chmod +x /wis2box-webapp/docker/generate-topic-list.sh \
    && chmod +x /wis2box-webapp/docker/healthcheck.sh

# Give ownership of the app to non-root user
RUN chown -R wis2box-webapp:wis2box-webapp /wis2box-webapp

# Switch to non-root user
USER wis2box-webapp

# expose port 4173
EXPOSE 4173

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD /wis2box-webapp/docker/healthcheck.sh

# Set the entrypoint
ENTRYPOINT ["sh", "/wis2box-webapp/docker/entrypoint.sh"]
