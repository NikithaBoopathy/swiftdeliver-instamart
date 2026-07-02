echo "=== JAVA ==="
java -version

echo "=== JENKINS ==="
systemctl is-active jenkins

echo "=== DOCKER ==="
systemctl is-active docker
docker --version

echo "=== SONARQUBE ==="
docker ps | grep sonarqube

echo "=== TRIVY ==="
trivy --version

echo "=== PORTS ==="
sudo ss -tulpn | egrep '8080|9000'
