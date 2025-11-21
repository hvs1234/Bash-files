#!/bin/bash

npm install react-redux react-icons react-router-dom @reduxjs/toolkit tailwindcss @tailwindcss/vite antd framer-motion

if ! grep -q "@tailwindcss/vite" vite.config.js; then
  sed -i '1s/^/import tailwindcss from "@tailwindcss\/vite";\n/' vite.config.js 2>/dev/null || sed -i '' '1s/^/import tailwindcss from "@tailwindcss\/vite";\n/' vite.config.js
  sed -i 's/plugins: \[/plugins: \[tailwindcss(), /' vite.config.js 2>/dev/null || sed -i '' 's/plugins: \[/plugins: \[tailwindcss(), /' vite.config.js
fi

rm -f src/App.css

cat <<EOF > src/index.css
@import "tailwindcss";

@layer utilities {
  .no-scrollbar::-webkit-scrollbar {
    display: none;
  }
  .no-scrollbar {
    -ms-overflow-style: none;
    scrollbar-width: none;
  }
  .custom-scrollbar::-webkit-scrollbar {
    height: 8px;
  }
  .custom-scrollbar::-webkit-scrollbar-track {
    background: #f1f1f1;
  }
  .custom-scrollbar::-webkit-scrollbar-thumb {
    background-color: #cacaca;
    border-radius: 10px;
  }
  .custom-scrollbar::-webkit-scrollbar-thumb:hover {
    background-color: rgb(170, 167, 167);
  }
}

* {
  font-family: 'Lato', sans-serif;
}

html {
  font-size: 100%;
  overflow-x: hidden;
}

body {
  font-weight: 500;
  background-color: #f4fcff;
  overflow-x: hidden;
}

@keyframes glow {
  0% {
    box-shadow: 0 0 5px rgba(105, 167, 195, 0.5), 0 0 10px rgba(72, 179, 228, 0.5);
    transform: scale(1);
  }
  50% {
    box-shadow: 0 0 5px rgb(255, 255, 255), 0 0 25px rgb(255, 255, 255);
    transform: scale(1.02);
  }
  100% {
    box-shadow: 0 0 5px rgba(255, 255, 255, 0.5), 0 0 10px rgba(255, 255, 255, 0.5);
    transform: scale(1);
  }
}

.custom-tooltip .ant-tooltip-inner {
  max-width: 400px !important;
  width: auto !important;
}

.glowing-img {
  animation: glow 1.5s ease-in-out infinite;
}

.custom-toast-container {
  font-size: 1.8rem;
  line-height: 1.5;
}

.Toastify__toast {
  border-radius: 8px !important;
  font-weight: 500 !important;
  font-size: 1.8rem !important;
  min-width: 500px !important;
  padding: 1.5rem 1.5rem !important;
}

.Toastify__toast--success {
  background: darkgreen !important;
  color: white !important;
  font-weight: 600 !important;
}

.Toastify__toast--success .Toastify__toast-icon svg {
  fill: white !important;
}

.Toastify__toast--info {
  background: rgb(96, 96, 195) !important;
  color: white !important;
  font-weight: 600 !important;
}

.Toastify__toast--info .Toastify__toast-icon svg {
  fill: white !important;
}

.Toastify__toast--error {
  background: orangered !important;
  color: white !important;
  font-weight: 600 !important;
}

.Toastify__toast--error .Toastify__toast-icon svg {
  fill: white !important;
}

.Toastify__toast--warning {
  background: rgb(161, 122, 24) !important;
  color: white !important;
  font-weight: 600 !important;
}

.Toastify__toast--warning .Toastify__toast-icon svg {
  fill: white !important;
}

.ant-switch-checked {
  background-color: goldenrod !important;
}

.custom-pagination .ant-pagination-item {
  border-radius: 9999px;
  border: 1px solid #d2d2d2;
  color: #666666;
}

.custom-pagination .ant-pagination-item-active {
  background-color: #111B69;
  border-color: transparent;
  color: white;
}

.custom-pagination .ant-pagination-item-active a {
  color: white !important;
}

.custom-pagination .ant-pagination-item:hover {
  border-color: #623AA2;
  color: #623AA2;
}

.custom-pagination .ant-pagination-prev .ant-pagination-item-link,
.custom-pagination .ant-pagination-next .ant-pagination-item-link {
  border-radius: 9999px;
  border: 1px solid #d2d2d2;
  color: #623AA2;
}

.custom-pagination .ant-pagination-disabled .ant-pagination-item-link {
  color: #a3a0a0 !important;
  cursor: not-allowed;
}

.custom-pagination .ant-pagination-options {
  display: inline-flex !important;
  visibility: visible !important;
}

.custom-pagination .ant-pagination-options-size-changer,
.custom-pagination .ant-pagination-options-quick-jumper {
  display: inline-flex !important;
  visibility: visible !important;
}

@media(max-width: 1500px) {
  html {
    font-size: 90%;
  }
}

@media(max-width: 1024px) {
  html {
    font-size: 80%;
  }
}
EOF

cat <<EOF > .env
VITE_BASE_URL=/
VITE_API_URL=http://localhost:5000/
EOF

cat <<EOF > Dockerfile
FROM node:18-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm install
COPY . .
RUN npm run build
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

cat <<EOF > .dockerignore
node_modules
dist
.git
.gitignore
Dockerfile
npm-debug.log
EOF
