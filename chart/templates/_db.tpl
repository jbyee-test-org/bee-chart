{{/* db provider 코덱 — capability `db` 를 모듈의 `spec.db.target` 으로 분기한다.
     선택 주체: db 는 모듈이 target 을 고른다(자기 migration SQL 이 DB 방언에 종속이라 모듈에 내재한 논리).
     seam 은 모듈 spec.db. target 은 기본값이 없어 미선언 시 실패한다.
     provider 엔트리(jdbcPrefix·port)는 platform.provides.db[] 데이터로, 차트가 치환한다.

     벤더 특성 격리: (a) migration SQL=모듈 소유(단일-target 라 평면, common/{vendor} 불요)
     (b) 접속=platform 데이터 (c) grants/schemas=이 헬퍼의 분기. flyway-job 자체는 벤더-중립. */}}

{{- define "bee.db.target" -}}
{{- $db := .Values.spec.db | default dict -}}
{{- $db.target | required "spec.db.target 필수(기본값 없음). psql|mysql 을 명시하라." -}}
{{- end -}}

{{- /* provides.db[] 에서 target 매칭 엔트리 → "jdbcPrefix|port|params"(helm 헬퍼는 문자열만 반환). 미매칭 시 실패.
       jdbcParams = provider별 접속 옵션(예: mysql 의 useSSL·allowPublicKeyRetrieval) — 접속 좌표 데이터이지 코덱 분기 아님. */ -}}
{{- define "bee.db._provider" -}}
{{- $t := include "bee.db.target" . -}}
{{- $hit := "" -}}
{{- range (((.Values.provides | default dict).db) | default list) -}}
{{- if eq (.target | toString) $t -}}{{- $hit = printf "%s|%v|%s" (.jdbcPrefix | toString) .port (.jdbcParams | default "") -}}{{- end -}}
{{- end -}}
{{- if not $hit -}}{{- fail (printf "db.target %q ∉ platform provides.db — platform.yaml 의 provides.db[].target 확인" $t) -}}{{- end -}}
{{- $hit -}}
{{- end -}}

{{- /* Flyway -url = provider 데이터(prefix·port·params) + 모듈 접속 좌표(dbHost·dbName). 분기 없음. */ -}}
{{- define "bee.db.url" -}}
{{- $e := splitList "|" (include "bee.db._provider" .) -}}
{{- $base := printf "%s://%s:%s/%s" (index $e 0) (.Values.dbHost | toString) (index $e 1) (.Values.dbName | default "bee") -}}
{{- $params := index $e 2 -}}
{{- if $params }}{{ printf "%s?%s" $base $params }}{{ else }}{{ $base }}{{ end -}}
{{- end -}}

{{- /* -schemas: psql=schema,public(search_path 결정화를 위해 public 동반) · mysql=schema(=database, public 없음).
       schema 미선언: psql=public · mysql=빈값(flyway-job 이 빈값이면 -schemas 생략). */ -}}
{{- define "bee.db.schemas" -}}
{{- $t := include "bee.db.target" . -}}
{{- $schema := (.Values.spec.db | default dict).schema -}}
{{- if eq $t "psql" -}}{{ if $schema }}{{ $schema }},public{{ else }}public{{ end }}{{- else -}}{{ $schema | default "" }}{{- end -}}
{{- end -}}

{{- /* grants 코덱 — 중립 vocab(grants:[{schema,access}]) → 벤더 SQL. role/user = bee_<rel>.
       psql=ROLE+schema grant+ALTER DEFAULT PRIVILEGES(future tables) · mysql=USER+db.* grant(future 자동). */ -}}
{{- define "bee.db.grantsSql" -}}
{{- $t := include "bee.db.target" . -}}
{{- $rel := .Release.Name -}}
{{- $db := .Values.spec.db | default dict -}}
{{- if eq $t "psql" -}}
DO $do$ BEGIN CREATE ROLE "bee_{{ $rel }}"; EXCEPTION WHEN duplicate_object THEN NULL; END $do$;
{{- range $db.grants }}
GRANT USAGE ON SCHEMA {{ .schema }} TO "bee_{{ $rel }}";
{{- if eq (.access | default "read") "read" }}
GRANT SELECT ON ALL TABLES IN SCHEMA {{ .schema }} TO "bee_{{ $rel }}";
ALTER DEFAULT PRIVILEGES IN SCHEMA {{ .schema }} GRANT SELECT ON TABLES TO "bee_{{ $rel }}";
{{- end }}
{{- end }}
{{- else if eq $t "mysql" -}}
CREATE USER IF NOT EXISTS 'bee_{{ $rel }}'@'%';
{{- range $db.grants }}
{{- if eq (.access | default "read") "read" }}
GRANT SELECT ON {{ .schema }}.* TO 'bee_{{ $rel }}'@'%';
{{- end }}
{{- end }}
{{- end -}}
{{- end -}}
