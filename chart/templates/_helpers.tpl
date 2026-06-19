{{- /* namespace — 배포 위치(좌표)는 주입받는다: bee up/publish 가 platform product→ns 룩업으로 --set 한다. */ -}}
{{- define "bee.namespace" -}}
{{ required "namespace 필요 — bee 가 platform product→ns 룩업으로 주입한다" .Values.namespace }}
{{- end -}}
