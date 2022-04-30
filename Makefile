.DELETE_ON_ERROR:

Q=@

GENS := $(addprefix packages/, sprinklers.yaml)				      \
	$(addprefix dashboards/, sprinklers.yaml)

DEFS := $(addprefix -D, SPRINKLER_HOST=hostname SPRINKLER_PORT=1234)

%.yaml: %.ypp yamlpp Makefile
	$Q echo Building $@
	$Q yamlpp $(DEFS) $< > $@

all: $(GENS)

clean:
	$Q $(RM) $(GENS)
