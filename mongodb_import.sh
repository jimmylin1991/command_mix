export MONGODB_USERNAME="admin" MONGODB_PASSWORD="Cmcc@_ZJ2025" && \
CURRENT_TIME=$(date -Iseconds) && \
CLASS_VALUE="cn.cmri.ai.entity.AgentAppSubscribe" && \
(head -1 appName_appId_apiKey_matched.csv | sed 's/$/,subscribeTime,_class/'; \
 tail -n +2 appName_appId_apiKey_matched.csv | while read line; do \
 echo "${line},\"${CURRENT_TIME}\",\"${CLASS_VALUE}\""; done) | \
mongoimport --db jt-llm-studio --collection AgentAppSubscribe \
--type csv --headerline --ignoreBlanks \
--username "$MONGODB_USERNAME" --password "$MONGODB_PASSWORD" \
--authenticationDatabase admin
