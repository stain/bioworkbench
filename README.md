# BioWorkbench

This repository contains a Docker recipe for the construction of BioWorkbench, a high-performance framework for managing and analyzing bioinformatics experiments.

Each experiment comprises a set of activities to be executed in a chained way, also known as workflows. Thus, they were modeled and defined using the Swift, a scientific workflow management system that allows them to run in high-performance computing environments.

The Docker recipe contains all the programs and configurations required to run the following workflows:

* SwiftGecko: https://github.com/mmondelli/swift-gecko

* SwiftPhylo: https://github.com/mmondelli/swift-phylo

* RASflow: https://github.com/mmondelli/rasflow

Please refer to the links above for a better description of each of the experiments, as well as instructions for their execution.

To build an image from the Dockerfile you can run (assuming you are inside the directory where the file is located):

```
docker build -t bioworkbench:latest .
```

To run a container for this image, you can run:

```
docker run --rm -p 3837:3838 --name bio bioworkbench:latest
```

And with this you can access a web interface to analyze the provenance of the workflows executed through the address:
http://localhost:3837/workbench

To run the experiments and other commands in the running container, you can use (from another terminal):

```
docker exec -ti bio /bin/bash
```



