FC = ifort
FCFLAGS = -xHost -O3 -heap-arrays

default: bulk_rhmc compile_flags

clean:
	rm bulk_rhmc compile_flags

bulk_rhmc: bulk_rhmc.f
	$(FC) $(FCFLAGS) -o $@ $^

compile_flags:
	echo $(FC) $(FCFLAGS) > $@
