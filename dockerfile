# Use Node.js as the base image to build the frontend
FROM node:16-alpine AS build

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and install dependencies
COPY package*.json ./
RUN npm install

# Copy the rest of the app code
COPY . .

# Build the React app
RUN npm run build

# Serve the build using Nginx
FROM nginx:alpine
COPY --from=build /app/build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
