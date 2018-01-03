ifndef TARGET
_fail:
	@echo "ERROR: Don't invoke this Makefile directly. See README.md"
endif # TARGET

CARTON_DIR			:= $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
-include $(CARTON_DIR)/config.mk	# Create and use this file to override any of 'Settings' #

# Settings #
ROOT				?=	..
OUT					?=	.output
NODEJS				?=	$(CARTON_DIR)/node_modules

# if JOBS are specified in config.mk, then use that to start a parallel build
ifdef JOBS
$(info [*] Running with $(JOBS) JOBS)
JOBS				:=	-j $(JOBS)
endif # JOBS

ifdef DEBUG
$(info [*] Debug output enabled)
endif # DEBUG

ifdef SOURCEMAPS
$(info [*] Source Maps enabled)
endif # SOURCEMAPS

# Input Dirs (modified by recursive scripts) #
INPUT_DIRS			?=	$(TARGET)/src/
INPUT_DIRS			:=	$(addprefix $(ROOT)/,$(INPUT_DIRS))
JS_LINT_IGNORE		:=	$(addprefix $(ROOT)/,$(JS_LINT_IGNORE) $(LINT_IGNORE))
CSS_LINT_IGNORE		:=	$(addprefix $(ROOT)/,$(CSS_LINT_IGNORE) $(LINT_IGNORE))
BUILD_DIR			:=	$(OUT)/.build

# Functions (must use '=', and not ':=') #
REMOVE_UNDERSCORE	=	$(foreach v,$(1),$(if $(findstring /_,$(v)),,$(v)))
#USE_INCLUDES		=	$(filter $(addsuffix %,$(dir $(INPUT_DIRS))),$(1))
#FIND_FILE			=	$(call REMOVE_UNDERSCORE,$(call USE_INCLUDES,$(shell find $(1) -name '$(2)')))
FIND_FILE			=	$(call REMOVE_UNDERSCORE,$(shell find $(1) -name '$(2)'))
# NOTE: My standard build tree rule is to ignore any file/dir prefixed with an underscore #

# Files #
ALL_JS_FILES		:=	$(filter-out %.min.js,$(call FIND_FILE,$(INPUT_DIRS),*.js))
ALL_LESS_FILES		:=	$(filter-out %.min.less,$(call FIND_FILE,$(INPUT_DIRS),*.less))
ALL_CSS_FILES		:=	$(filter-out %.min.css,$(call FIND_FILE,$(INPUT_DIRS),*.css))
ALL_SVG_FILES		:=	$(filter-out %.min.svg,$(call FIND_FILE,$(INPUT_DIRS),*.svg))

ALL_ESIGNORE_FILES	:=	$(call FIND_FILE,$(INPUT_DIRS),.esignore)
ESIGNORE_DIRS		:=	$(addsuffix %,$(dir $(ALL_ESIGNORE_FILES)))

# Transforms #
ES_FILES 			:=	$(filter-out $(ESIGNORE_DIRS),$(ALL_JS_FILES))
JS_FILES 			:=	$(filter $(ESIGNORE_DIRS),$(ALL_JS_FILES))
LESS_FILES			:=	$(ALL_LESS_FILES)
CSS_FILES			:=	$(ALL_CSS_FILES)
SVG_FILES			:=	$(ALL_SVG_FILES)

OUT_ES_FILES		:=	$(subst $(ROOT)/,$(OUT)/,$(ES_FILES:.js=.es.js))
OUT_JS_FILES		:=	$(subst $(ROOT)/,$(OUT)/,$(JS_FILES:.js=.o.js))
OUT_LESS_FILES		:=	$(subst $(ROOT)/,$(OUT)/,$(LESS_FILES:.less=.less.css))
OUT_CSS_FILES		:=	$(subst $(ROOT)/,$(OUT)/,$(CSS_FILES:.css=.o.css))
OUT_SVG_FILES		:=	$(subst $(ROOT)/,$(OUT)/,$(SVG_FILES:.svg=.min.svg))

OUT_FILES_SVG		:=	$(strip $(OUT_SVG_FILES))
OUT_FILES_CSS		:=	$(strip $(OUT_CSS_FILES) $(OUT_LESS_FILES))
OUT_FILES_JS		:=	$(strip $(OUT_JS_FILES) $(OUT_ES_FILES))
OUT_FILES			:=	$(strip $(OUT_FILES_SVG) $(OUT_FILES_CSS) $(OUT_FILES_JS))
DEP_FILES			:=	$(strip $(addsuffix .dep,$(OUT_ES_FILES) $(OUT_LESS_FILES)))
OUT_DIRS			:=	$(strip $(sort $(dir $(OUT_FILES) $(BUILD_DIR)/)))

ifneq ($(OUT_FILES_SVG),)
TARGET_FILES_SVG	:=	out.min.svg
endif # OUT_FILES_SVG
ifneq ($(OUT_FILES_CSS),)
TARGET_FILES_CSS	:=	out.min.css
ifdef DEBUG
TARGET_FILES_CSS	+=	out.debug.css
endif # DEBUG
endif # OUT_FILES_CSS
ifneq ($(OUT_FILES_JS),)
TARGET_FILES_JS		:=	out.min.js
ifdef DEBUG
TARGET_FILES_JS		+=	out.debug.js
endif # DEBUG
endif # OUT_FILES_JS
TARGET_FILES		:=	$(TARGET_FILES_SVG) $(TARGET_FILES_CSS) $(TARGET_FILES_JS)


# Tools #

# Ecmascript Linter: http://eslint.org/
ESLINT_ARGS			:=	--config $(CARTON_DIR)/config/eslint.config.json
ESLINT				=	$(NODEJS)/eslint/bin/eslint.js $(1) $(ESLINT_ARGS)
# ES Compiler: https://buble.surge.sh/guide/
BUBLE_ARGS			:=	--no modules --jsx h --objectAssign Object.assign
#ifdef SOURCEMAPS
#BUBLE_ARGS			+=	-m inline
#endif # SOURCEMAPS
BUBLE				=	$(NODEJS)/buble/bin/buble $(BUBLE_ARGS) -i $(1) -o $(2)
# ES Include/Require Resolver: http://rollupjs.org/guide/
ROLLUP_ARGS			:=	-c $(CARTON_DIR)/config/rollup.config.js
ifdef SOURCEMAPS
ROLLUP_ARGS			+=	-m inline
endif # SOURCEMAPS
ROLLUP				=	$(NODEJS)/rollup/bin/rollup $(ROLLUP_ARGS) $(1) > $(2)
# JS Preprocessor: https://github.com/moisesbaez/preprocess-cli-tool
JS_PP_DEBUG			=	$(NODEJS)/preprocess-cli-tool/bin/preprocess.js -f $(1) -d $(2) -c '{"DEBUG": true}' -t js
JS_PP_RELEASE		=	$(NODEJS)/preprocess-cli-tool/bin/preprocess.js -f $(1) -d $(2) -t js
# JS Minifier: https://github.com/mishoo/UglifyJS2
MINIFY_JS_RESERVED	:=	VERSION_STRING,STATIC_DOMAIN
MINIFY_JS_ARGS		:=	--compress --mangle -r "$(MINIFY_JS_RESERVED)"
MINIFY_JS			=	$(NODEJS)/uglify-js/bin/uglifyjs $(MINIFY_JS_ARGS) -o $(2) -- $(1)

# CSS Compiler: http://lesscss.org/
LESS_COMMON			:=	--global-var='STATIC_DOMAIN=$(STATIC_DOMAIN)' --include-path=$(ROOT)
LESS_ARGS			:=	--autoprefix
LESS_DEP			=	$(NODEJS)/less/bin/lessc $(LESS_COMMON) --depends $(1) $(2)>$(2).dep
LESS				=	$(NODEJS)/less/bin/lessc $(LESS_COMMON) $(LESS_ARGS) $(1) $(2)
# CSS Minifier: https://github.com/jakubpawlowicz/clean-css/
MINIFY_CSS			=	cat $(1) | $(NODEJS)/clean-css-cli/bin/cleancss -o $(2)
# CSS Linter: http://stylelint.io/
STYLELINT_ARGS		:=	--syntax less --config $(CARTON_DIR)/config/.stylelintrc
STYLELINT			=	$(NODEJS)/stylelint/bin/stylelint.js $(1) $(STYLELINT_ARGS)

# SVG "Compiler", same as the minifier: https://github.com/svg/svgo
SVGO_ARGS			:=	-q --disable=removeTitle --disable=removeDimensions --disable=removeViewBox
SVGO				=	$(NODEJS)/svgo/bin/svgo $(SVGO_ARGS) -i $(1) -o $(2)
# Mike's SVG Sprite Packer: https://github.com/povrazor/svg-sprite-tools
SVG_PACK			=	$(CARTON_DIR)/svg-tools/svg-sprite-pack $(1) > $(2)
# SVG Minifier: https://github.com/svg/svgo
MINIFY_SVG_ARGS		:=	--multipass --disable=cleanupIDs -q
MINIFY_SVG			=	$(NODEJS)/svgo/bin/svgo $(MINIFY_SVG_ARGS) -i $(1) -o $(2)

# Remove Empty Directories
RM_EMPTY_DIRS		=	find $(1) -type d -empty -delete 2>/dev/null |true

# Get size in bytes (compress and uncompressed)
SIZE				=	cat $(1) | wc -c
GZIP_SIZE			=	gzip -c $(1) | wc -c


# Rules #
default: target

report: $(TARGET_FILES)
	@echo \
		"[JS_RAW]  GZIP: `$(call GZIP_SIZE,$(BUILD_DIR)/all.js 2>/dev/null)` MINIFY: N/A	ORIGINAL: `$(call SIZE,$(BUILD_DIR)/all.js 2>/dev/null)`\n" \
		"[JS_DEBUG]  GZIP: `$(call GZIP_SIZE,out.debug.js 2>/dev/null)` MINIFY: `$(call SIZE,out.debug.js 2>/dev/null)`*	ORIGINAL: `$(call SIZE,$(BUILD_DIR)/all.debug.js 2>/dev/null)`\n" \
		"[JS_RELEASE]  GZIP: `$(call GZIP_SIZE,out.min.js 2>/dev/null)`   MINIFY: `$(call SIZE,out.min.js 2>/dev/null)`    ORIGINAL: `$(call SIZE,$(BUILD_DIR)/all.release.js 2>/dev/null)`\n" \
		"[CSS]     GZIP: `$(call GZIP_SIZE,out.min.css 2>/dev/null)`  MINIFY: `$(call SIZE,out.min.css 2>/dev/null)`	ORIGINAL: `$(call SIZE,$(BUILD_DIR)/all.css 2>/dev/null)`\n" \
		"[SVG]     GZIP: `$(call GZIP_SIZE,out.min.svg 2>/dev/null)`  MINIFY: `$(call SIZE,out.min.svg 2>/dev/null)`	ORIGINAL: `$(call SIZE,$(BUILD_DIR)/all.svg 2>/dev/null)`\n" \
		| column -t

# Dir Rules #
$(OUT_DIRS):
	mkdir -p $@


lint-svg:
lint-css: $(LESS_FILES)
	$(call STYLELINT,$^)
lint-js: $(ES_FILES)
	$(call ESLINT,$^)
lint-php:

clean-lint:
	rm -fr $(BUILD_DIR)/buble.lint $(BUILD_DIR)/less.lint


$(BUILD_DIR)/buble.lint: $(filter-out $(addsuffix %,$(JS_LINT_IGNORE)),$(ES_FILES))
	$(call ESLINT,$?)
	@touch $@


$(BUILD_DIR)/less.lint: $(filter-out $(addsuffix %,$(CSS_LINT_IGNORE)),$(LESS_FILES))
ifneq ($(LESS_FILES),)
	$(call STYLELINT,$?)
endif # ES_FILES
	@touch $@


# File Rules #
$(OUT)/%.es.js:$(ROOT)/%.js
	$(call BUBLE,$<,$@)

$(OUT)/%.o.js:$(ROOT)/%.js
	cp $< $@

$(OUT)/%.less.css:$(ROOT)/%.less
	$(call LESS,$<,$@); $(call LESS_DEP,$<,$@)

$(OUT)/%.o.css:$(ROOT)/%.css
	cp $< $@

$(OUT)/%.min.svg:$(ROOT)/%.svg
	$(call SVGO,$<,$@)


clean:
	rm -fr $(OUT) $(TARGET_FILES)
clean-svg:
	rm -fr $(OUT_FILES_SVG) $(OUT_FILES_SVG:.svg=.svg.out) $(TARGET_FILES_SVG) $(BUILD_DIR)/svg.svg $(BUILD_DIR)/all.svg
	-$(call RM_EMPTY_DIRS,.output)
clean-css:
	rm -fr $(OUT_CSS_FILES) $(OUT_LESS_FILES) $(OUT_LESS_FILES:.less.css=.less) $(OUT_LESS_FILES:.less.css=.less.css.dep) $(TARGET_FILES_CSS) $(BUILD_DIR)/less.css $(BUILD_DIR)/css.css $(BUILD_DIR)/less.lint $(BUILD_DIR)/all.css
	-$(call RM_EMPTY_DIRS,.output)
clean-js:
	rm -fr $(OUT_JS_FILES) $(OUT_ES_FILES) $(OUT_ES_FILES:.es.js=.js) $(OUT_ES_FILES:.es.js=.js.dep) $(TARGET_FILES_JS) $(BUILD_DIR)/js.js $(BUILD_DIR)/buble.js $(BUILD_DIR)/buble.lint $(BUILD_DIR)/all.js
	-$(call RM_EMPTY_DIRS,.output)


OUT_MAIN_JS			:=	$(addprefix $(OUT)/,$(MAIN_JS:.js=.es.js)))


# JavaScript #
$(BUILD_DIR)/js.js: $(OUT_JS_FILES)
ifneq ($(OUT_JS_FILES),)
	cat $^ > $@
else
	touch $@
endif # OUT_JS_FILES
$(BUILD_DIR)/buble.js: $(OUT_MAIN_JS) $(OUT_ES_FILES)
	$(call ROLLUP,$<,$@.tmp)
	rm -f $@
	mv $@.tmp $@
$(BUILD_DIR)/all.js: $(BUILD_DIR)/js.js $(BUILD_DIR)/buble.js
	cat $^ > $@
$(BUILD_DIR)/all.release.js: $(BUILD_DIR)/all.js
	$(call JS_PP_RELEASE,$<,$@)
out.min.js: $(BUILD_DIR)/all.release.js
	$(call MINIFY_JS,$<,$@)
$(BUILD_DIR)/all.debug.js: $(BUILD_DIR)/all.js
	$(call JS_PP_DEBUG,$<,$@)
out.debug.js: $(BUILD_DIR)/all.debug.js
	cp -f --remove-destination $< $@

#	$(call JS_PP_DEBUG,$<,$(@D)/all.debug.js)

#	$(call MINIFY_JS,$<,$@)
#
#ifdef DEBUG
#	cp -f --remove-destination $(<D)/all.debug.js $(@D)/all.debug.js
#endif


# CSS #
$(BUILD_DIR)/css.css: $(OUT_CSS_FILES)
ifneq ($(OUT_CSS_FILES),)
	cat $^ > $@
else
	touch $@
endif # $(OUT_CSS_FILES)
$(BUILD_DIR)/less.css: $(OUT_LESS_FILES)
ifneq ($(OUT_LESS_FILES),)
	cat $^ > $@
else
	touch $@
endif # $(OUT_LESS_FILES)
$(BUILD_DIR)/all.css: $(BUILD_DIR)/css.css $(BUILD_DIR)/less.css
	cat $^ > $@
out.min.css: $(BUILD_DIR)/all.css
	$(call MINIFY_CSS,$<,$@)
out.debug.css: $(BUILD_DIR)/all.css
	cp -f --remove-destination $< $@

#ifdef DEBUG
#	cp -f --remove-destination $< $(@D)/all.debug.css
#endif


# SVG # src/icons/icomoon/icons.svg
$(BUILD_DIR)/svg.svg: $(OUT_SVG_FILES)
	$(call SVG_PACK,$^,$@.out)
	rm -f $@
	mv $@.out $@
	# NOTE: needs to work like this, 'cause SVG_PACK outputs to stdout. Otherwise we wont stop on SVG errors
$(BUILD_DIR)/all.svg: $(BUILD_DIR)/svg.svg
	cat $^ > $@
out.min.svg: $(BUILD_DIR)/all.svg
	$(call MINIFY_SVG,$<,$@)


# Target #
target: $(OUT_DIRS) $(BUILD_DIR)/buble.lint $(BUILD_DIR)/less.lint $(TARGET_FILES) report
	@echo "[-] Done \"$(subst /,,$(TARGET))\""


info:
	@echo "ROOT: $(ROOT)"
	@echo "OUT: $(OUT)"
	@echo ""
	@echo "INPUT_DIRS: $(INPUT_DIRS)"
	@echo ""
	@echo "SVG: $(SVG_FILES)"
	@echo "LESS: $(LESS_FILES)"
	@echo "CSS: $(CSS_FILES)"
	@echo "ES: $(ES_FILES)"
	@echo "JS: $(JS_FILES)"

# Phony Rules #
.PHONY: default info build target all clean clean-all clean-target clean-lint clean-svg clean-css clean-js clean-all-svg clean-all-css clean-all-js lint lint-all lint-svg lint-css lint-js lint-php lint-all-svg lint-all-css lint-all-js lint-all-php fail report $(BUILDS)


# Dependencies #
-include $(DEP_FILES)
