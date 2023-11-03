# Build documents
build:
	mkdir -p ".cache/texmf-var" "build"
	ln -sf ../{bib,data,tex} -t "build"
	env TEXMFHOME=.cache TEXMFVAR=.cache/texmf-var latexmk

# Clean build directory
clean:
	latexmk -c
