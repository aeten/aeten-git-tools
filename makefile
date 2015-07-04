AETEN_CLI_DIR := ./aeten-cli
prefix := /usr/local
bin := $(prefix)/bin
lib := $(prefix)/lib
include_cli := true

SCRIPT = aeten-submodules.sh
COMMANDS = $(shell $$(pwd)/$(SCRIPT) __api)
LINKS = $(addprefix $(bin)/,$(COMMANDS))
LIB_DIR = $(shell readlink -f "$$(test '$(lib)' = '$$(pwd)' && echo $(lib) || echo $(lib))")

CUR_DIR = $(shell readlink -f "$(CURDIR)")
AETEN_CLI = \#@@AETEN-CLI-INCLUDE@@
AETEN_CLI_SCRIPT = $(AETEN_CLI_DIR)/aeten-cli.sh

check = $(AETEN_CLI_SCRIPT) check
git_submodule = ". $(AETEN_CLI_SCRIPT) '&&' aeten_cli_import $(AETEN_CLI_SCRIPT) all '&&' . ./$(SCRIPT) '&&'"

ifeq ($(LIB_DIR),$(CUR_DIR))
GITIGNORE = .gitignore
endif

.PHONY: all clean install uninstall
all:

%.sh: %.sh.template

.gitignore: $(SCRIPT)
	@$(check) -m 'Update .gitignore' "echo .gitignore > .gitignore && sed --quiet --regexp-extended 's/^(git-[[:alnum:]_-]+)\s*\(\)\s*\{/\1/p' $< >> .gitignore"

install: $(LINKS) $(GITIGNORE)

uninstall:
	@test "$(CUR_DIR)" = "$(LIB_DIR)" || $(check) -m 'Uninstall lib' rm -f $(LIB_DIR)/$(SCRIPT)
	@$(check) -m 'Uninstall symlinks' rm -f $(LINKS)

clean:
	@test -f .gitignore && $(check) -m 'Remove .gitignore' rm -f .gitignore || true

ifneq ($(LIB_DIR),$(CUR_DIR)) # Prevent circular dependency
$(LIB_DIR)/%: %
ifeq (true,$(include_cli))
	@$(check) -m 'Check submodule checkout' test -f $(AETEN_CLI_SCRIPT)
ifeq (./aeten-cli,$(AETEN_CLI_DIR))
	@-$(check) -l warn -m "Check submodule checkout revision" $(git_submodule) git-submodule-check aeten-cli
endif
	@$(check) -m 'Install lib $@ with aeten-cli inclusion' "sed -e '/$(AETEN_CLI)/r $(AETEN_CLI_SCRIPT)' -e '/$(AETEN_CLI)/a \\\naeten_cli_import \$${0} all' -e '/$(AETEN_CLI)/d' $< > $@"
else
	@$(check) -m 'Install lib $@' cp $< $@
endif
	@$(check) -m 'Set exec flag to $@' chmod a+rx $@
endif

$(LINKS): $(LIB_DIR)/$(SCRIPT)
	@$(check) -m 'Install symlink $@' ln -s $< $@
