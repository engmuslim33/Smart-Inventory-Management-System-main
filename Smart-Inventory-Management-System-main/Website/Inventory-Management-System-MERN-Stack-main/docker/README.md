# دليل تسليم الـ Docker (للي بعدنا: إبراهيم - Kubernetes)

## أولاً: إحنا عملنا إيه؟

عملنا **Dockerfile لكل جزء في المشروع**، وملف **docker-compose.yml** يربطهم كلهم ببعض.

| الجزء | فولدره | البورت | الـ Image |
|---|---|---|---|
| API Gateway | `Backend/api-gateway` | 4000 | `ims/api-gateway:1.0.0` |
| Auth Service | `Backend/auth-service` | 4001 | `ims/auth-service:1.0.0` |
| Product Service | `Backend/product-service` | 4002 | `ims/product-service:1.0.0` |
| Order Service | `Backend/order-service` | 4003 | `ims/order-service:1.0.0` |
| Inventory Service | `Backend/inventory-service` | 4004 | `ims/inventory-service:1.0.0` |
| Statistics Service | `Backend/statistics-service` | 4005 | `ims/statistics-service:1.0.0` |
| Frontend (React + Nginx) | `Frontend` | 80 | `ims/frontend:1.0.0` |
| MongoDB | (image جاهز) | 27017 | `mongo:7` |

### مميزات الـ Dockerfiles بتاعتنا
- **Multi-stage build**: الـ image النهائي صغير.
- الـ Backend بيشتغل بمستخدم `node` (مش root) للأمان.
- كل service فيها **HEALTHCHECK** على `/health`.
- الـ Frontend: بيتبني بـ Vite وبيتقدّم بـ Nginx.
- كل فولدر فيه `.dockerignore`.

## ثانياً: إزاي تشغّله محلياً؟

```bash
docker compose up --build
```

- الموقع: http://localhost:3000
- الـ Gateway: http://localhost:4000/health

## ثالثاً: متغيرات البيئة المطلوبة

**كل service:** متغير البورت بتاعها (`AUTH_SERVICE_PORT`, `PRODUCT_SERVICE_PORT`, `ORDER_SERVICE_PORT`, `INVENTORY_SERVICE_PORT`, `STATISTICS_SERVICE_PORT`, وللـ gateway `GATEWAY_PORT`).

**روابط MongoDB (قاعدة بيانات لكل service):**
- `AUTH_MONGO_URI` = `mongodb://mongo:27017/inventory_auth`
- `PRODUCT_MONGO_URI` = `mongodb://mongo:27017/inventory_products`
- `ORDER_MONGO_URI` = `mongodb://mongo:27017/inventory_orders`
- `INVENTORY_MONGO_URI` = `mongodb://mongo:27017/inventory_inventory`
- `STATISTICS_MONGO_URI` = `mongodb://mongo:27017/inventory_statistics`

**أسرار (استخدم Kubernetes Secret):**
- `JWT_SECRET`: في **auth-service** و**api-gateway**، ولازم نفس القيمة بالظبط.
- `JWT_EXPIRES_IN`: في auth-service (الافتراضي `1d`).

**روابط الـ services (استخدم أسماء الـ Services في Kubernetes):**
- order-service: `INVENTORY_SERVICE_URL`
- statistics-service: `AUTH_SERVICE_URL`, `PRODUCT_SERVICE_URL`, `ORDER_SERVICE_URL`, `INVENTORY_SERVICE_URL`
- api-gateway: `AUTH_SERVICE_URL`, `PRODUCT_SERVICE_URL`, `ORDER_SERVICE_URL`, `INVENTORY_SERVICE_URL`, `STATISTICS_SERVICE_URL`

مثال: `AUTH_SERVICE_URL=http://auth-service:4001`

## رابعاً: المطلوب منك يا إبراهيم في Kubernetes

### 1. الـ Deployments والـ Services
اعمل Deployment + Service لكل واحد من الـ 7 (الـ 6 services والـ Frontend). أسماء الـ Services لازم تكون **زي أسماء الـ services في docker-compose بالظبط**:
`auth-service`, `product-service`, `order-service`, `inventory-service`, `statistics-service`, `api-gateway`, `frontend`, `mongo`.

> ⚠️ **مهم جداً:** الـ Service بتاع الـ gateway لازم اسمه **`api-gateway`** وبورته **4000**، لأن ملف `Frontend/nginx.conf` بيعمل proxy لـ `http://api-gateway:4000`. لو غيّرت الاسم الموقع مش هيكلّم الـ API.

### 2. MongoDB
- Deployment (أو StatefulSet) + **PersistentVolumeClaim** متركّب على `/data/db`.
- Service اسمه `mongo` على بورت 27017.

### 3. ConfigMap
حط فيه روابط الـ Mongo وروابط الـ services والبورتات.

### 4. Secret
حط فيه `JWT_SECRET` (نفس القيمة للـ auth والـ gateway).

### 5. Probes
استخدم `/health` لـ **liveness** و**readiness** في كل الـ Node services. الـ Frontend: `GET /`.

### 6. Resources
حدد `requests` و`limits` لكل container.

### 7. Ingress / تعريض الموقع للخارج
الـ Frontend (بورت 80) هو الوحيد اللي لازم يتعرّض للخارج (Ingress أو NodePort/LoadBalancer). باقي الـ services داخلية بس.

### 8. Rolling updates و scaling
- استراتيجية `RollingUpdate`.
- جرّب `HPA` على الـ services الأساسية.

### 9. Images
- في Minikube: `eval $(minikube docker-env)` ثم ابني الـ images، أو ارفعهم على Docker Hub/ECR.
- **ماتستخدمش `latest`**، استخدم الـ tags الثابتة (`1.0.0`).

## خامساً: ملاحظات مهمة

1. في فولدر `k8s/` من المشروع القديم manifests جاهزة، **اقراها كمرجع** بس اكتب بتاعتك.
2. في `Frontend/` فيه `dockerfile.k8s` و`Dockerfile.test` (لسه القدام). اتفق معانا أنهي Dockerfile هتستخدمه.
3. الـ Dockerfiles بتستخدم `npm install` لأن `package-lock.json` مش موجود. لما يتضاف نحوّلها لـ `npm ci`.
4. الـ Jenkins (أحمد وليد) هيبني الـ images من نفس الـ Dockerfiles.

## سادساً: حالة الاختبار

- ✅ **اتجرّبوا فعلياً وشغالين:** auth-service, product-service, order-service (build + run + `/health` + اتصال MongoDB).
- ⏳ **لسه ما اتجرّبوش:** inventory-service, statistics-service, api-gateway, Frontend, و `docker compose up` كامل (بسبب مشكلة في Docker Desktop على جهاز كاتب الـ Dockerfiles).

لو لقيت أي خطأ في الـ build أو التشغيل، ابعتلنا الـ error.