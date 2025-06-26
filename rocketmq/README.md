# RocketMQ 快速啟動與使用教學

## 專案簡介
本專案提供 Apache RocketMQ 5.3.2 以 Docker Compose 快速部署的範例，適合本地開發、測試與學習。包含 NameServer、Broker 及 Proxy 組件，並已預設好常用配置。

---

## 目錄結構

```
rocketmq/
├── broker.conf         # Broker 主要設定檔
├── docker-compose.yaml # Docker Compose 啟動配置
└── README.md           # 教學與說明文件
```

---

## 快速啟動步驟

1. **安裝 Docker 與 Docker Compose**
   - 請先安裝 [Docker Desktop](https://www.docker.com/products/docker-desktop/)（支援 macOS、Windows、Linux）。

2. **啟動 RocketMQ 叢集**
   ```sh
   cd rocketmq
   docker compose up -d
   ```
   - 預設會啟動 NameServer（9876）、Broker（10909/10911/10912）、Proxy（8080/8081）

3. **檢查服務狀態**
   ```sh
   docker compose ps
   docker compose logs -f
   ```
   - 若看到 `rocketmq-proxy startup successfully` 代表啟動成功。

4. **停止 RocketMQ 叢集**
   ```sh
   docker compose down
   ```

---

## broker.conf 說明

`broker.conf` 主要設定 Broker 的叢集名稱、角色、ID 及自動主題建立等功能。

```properties
brokerClusterName=DefaultCluster
brokerName=broker-a
brokerId=0
deleteWhen=04
fileReservedTime=48
brokerRole=ASYNC_MASTER
flushDiskType=ASYNC_FLUSH
autoCreateTopicEnable=true
autoDeleteTopicEnable=true
```
- **brokerClusterName**：叢集名稱，需與 docker-compose.yaml 一致
- **brokerName**：Broker 名稱
- **brokerId**：0 代表 Master，>0 代表 Slave
- **autoCreateTopicEnable**：允許自動建立主題（Proxy 必須開啟）
- 其餘參數可參考 [官方文件](https://rocketmq.apache.org/zh/docs/5.x/)

---

## 常見問題與排解

- **Proxy 啟動時出現 `create system broadcast topic ... failed`？**
  - 這是因為 broker 尚未 fully ready，Proxy 會自動重試，最終看到 `rocketmq-proxy startup successfully` 即可。
- **如何清理孤兒容器？**
  ```sh
  docker compose down --remove-orphans
  ```
- **如何修改 Broker 設定？**
  - 編輯 `broker.conf`，然後重啟 broker：
    ```sh
    docker compose restart broker
    ```

---

## 參考連結
- [RocketMQ 官方文件（繁體/簡體）](https://rocketmq.apache.org/zh/docs/5.x/)
- [Docker 官方網站](https://www.docker.com/)
- [RocketMQ Github](https://github.com/apache/rocketmq)

---

如有問題歡迎提 issue 或討論！ 