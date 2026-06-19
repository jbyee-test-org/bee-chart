{{- /* namespace — 좌표는 주입받는다(G12④): bee up/publish 가 platform product→ns 룩업으로 --set. */ -}}
{{- define "bee.namespace" -}}
{{ required "namespace 필요 — bee 가 platform product→ns 룩업으로 주입한다(G12④)" .Values.namespace }}
{{- end -}}
