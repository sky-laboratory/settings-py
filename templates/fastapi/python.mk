# Root Makefile in each service repo
# ==================================
# settings-py/templates/{TEMPLATE}/python.mk + pyproject.toml 을
# "init-settings" 때만 받아오고,
# 그 이후에는 그냥 실행만 하는 모드.

TEMPLATE ?= $(shell sed -n 's/^TEMPLATE=//p' .settings-template)

ifeq ($(TEMPLATE),)
$(error TEMPLATE is not set. Create .settings-template with TEMPLATE=fastapi or TEMPLATE=django)
endif

# settings-py 템플릿 위치 (루트까지만)
SETTINGS_PY_BASE_URL ?= https://raw.githubusercontent.com/sky-laboratory/settings-py/main/templates

PYPROJECT_URL   := $(SETTINGS_PY_BASE_URL)/$(TEMPLATE)/pyproject.toml
REMOTE_MK_URL   := $(SETTINGS_PY_BASE_URL)/$(TEMPLATE)/python.mk

LOCAL_PYPROJECT := pyproject.toml
LOCAL_REMOTE_MK := .python-template.mk

# 1) 명시적으로 한 번만 실행하는 초기 셋업
.PHONY: init-settings
init-settings:
	@echo ">>> [settings-py] init for TEMPLATE=$(TEMPLATE)"
	@echo ">>> fetching pyproject.toml from $(PYPROJECT_URL)"
	@curl -sS $(PYPROJECT_URL) -o $(LOCAL_PYPROJECT)
	@echo ">>> fetching python.mk from $(REMOTE_MK_URL)"
	@curl -sS $(REMOTE_MK_URL) -o $(LOCAL_REMOTE_MK)
	@echo ">>> [settings-py] init done."

.PHONY: sync-pyproject
sync-pyproject:
	@echo ">>> [settings-py] sync pyproject.toml from $(PYPROJECT_URL)"
	@curl -sS $(PYPROJECT_URL) -o $(LOCAL_PYPROJECT)

.PHONY: sync-mk
sync-mk:
	@echo ">>> [settings-py] sync python.mk from $(REMOTE_MK_URL)"
	@curl -sS $(REMOTE_MK_URL) -o $(LOCAL_REMOTE_MK)

# 2) .python-template.mk 없으면 실행 자체를 막음 (자동 다운로드 X)
ifeq ("$(wildcard $(LOCAL_REMOTE_MK))","")
$(error $(LOCAL_REMOTE_MK) not found. Run 'make init-settings' first.)
endif

# 3) 나머지 모든 타겟은 템플릿으로 위임 (실행만)
%:
	@$(MAKE) -f $(LOCAL_REMOTE_MK) $@ TEMPLATE=$(TEMPLATE)