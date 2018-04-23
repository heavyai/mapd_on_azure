# Start MapD
docker run --runtime=nvidia \
-v $HOME/mapd-docker-storage:/mapd-storage \
-p 9090-9092:9090-9092 \
mapd/mapd-ce-cuda
