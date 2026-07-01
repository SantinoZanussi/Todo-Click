# Imagen del backend de TodoClick.
# Sirve para Cloud Run, Railway, Render, Fly.io, etc.
FROM node:20-slim

WORKDIR /usr/src/app

# Dependencias de producción primero (mejor uso de la caché de capas).
COPY package.json package-lock.json* ./
RUN npm install --omit=dev

# Código de la app.
COPY . .

ENV NODE_ENV=production
# La plataforma inyecta la variable PORT; el server la lee (default 8080).
EXPOSE 8080

CMD ["node", "src/index.js"]
