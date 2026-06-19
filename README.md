# bee-chart — bee-module 공용 차트 (엔진, 플랫폼 비종속)

bee 엔진의 **매니페스트 파생 차트**. 매니페스트 파생 로직이 사는 곳 — 모듈의 논리 선언
(`module.yaml` + `values-<env>`)을 받아 k8s 매니페스트로 렌더한다. **특정 플랫폼·제품·org 지식 0**
(순수 제네릭 — 어떤 플랫폼에도 결합되지 않는다). 차트는 자기만의 레포에서 독립적으로 관리된다.

## 위치

엔진 레포셋: `bee-cli`(오케스트레이터) · **`bee-chart`(이 레포 — 파생 차트)** ⊥ 인스턴스: `<platform>-core-infra`
(platform.yaml·argocd·substrate) · `<platform>-snapshot`(렌더 SoT) · 모듈 N. 차트를 엔진에서 분리해
자기 버전·릴리스 주기를 가지므로, 차트 갱신이 엔진 릴리스에 묶이지 않는다.

## 소비 (OCI)

차트는 **저작되는 곳이 아니라 OCI 로 소비**된다. 모듈은 `module.yaml spec.chart.version` 으로 pin,
워크스페이스는 `coreInfra.chartRef: oci://ghcr.io/<org>/charts/bee-module` 로 가리킨다. bee 가
`helm ... --version <pin>` 으로 OCI 에서 당겨 렌더(파생은 차트, bee 는 호출만).

## 릴리스

`.github/workflows/chart-release.yaml`(workflow_dispatch) — `Chart.yaml` 의 version 으로 `helm package`
+ `helm push oci://ghcr.io/<owner>/charts`. **version bump = 명시**(SemVer; v1 필드 불변=patch/minor, additive).
모듈 pin 이 그대로 `--version` 이 되므로, 발행 버전과 모듈 pin 이 계약을 이룬다.

## 코덱 (provider-rendering)

`_routing.tpl`(routing: kong↔nginx) · `_db.tpl`(db: postgres↔mysql) — capability→provider→템플릿 dispatch.
seam 인터페이스 = 안정된 어휘(`spec.routing`·`spec.db`). 새 provider 분기는 *엔진 기여*(기존 동작에 더하는
방식, 모든 플랫폼 공유) — 플랫폼마다 fork 하지 않는다.

## 스키마

`values.schema.json` = values 계약. 검증 = helm + CI lint(`conftest`), **CLI 검증 안 함**(검증은 CI 의 몫).

## License

[MIT](LICENSE) © 2026 BetweenBits, Jonghyeon Park
