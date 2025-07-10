FROM public.ecr.aws/docker/library/node:18-alpine
WORKDIR /app
COPY index.js ./
RUN npm init -y && npm install express
EXPOSE 80
CMD ["node", "index.js"]
