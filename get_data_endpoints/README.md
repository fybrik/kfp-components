# Fybrik KFP component

This is a component that can be used in Kubeflow Pipelines to read two input datasets (ex: test and training data), and to write the results of whatever
processing is done on that data **in a secure and governed fashion by leveraging Fybrik**

It is assumed that Fybrik is installed together with the chosen Data Catalog and Data Governance engine, and that:

* training and testing datasets have been registered in the data catalog
* governance policies have been defined in the data governance engine

## Prerequisits

* [Install kubeflow pipelines](https://www.kubeflow.org/docs/components/pipelines/installation/overview/#kubeflow-pipelines-standalone).
  * To install on kind, see [these instructions](https://github.com/machine-learning-exchange/mlx/blob/main/docs/install-mlx-on-kind.md#install-kubeflow-pipelines-for-reference-only-optional).  
    * Please note that if you are running k8s 1.22 or higher on kind PIPELINE_VERSION should be 1.8.5 and not as indicated in the instructions.
  * Installation takes time.  Pods often take restart repeatedly until all become ready.
* [Install Fybrik](https://fybrik.io/v1.0/get-started/quickstart/)
* [Deploy Datashim](https://github.com/datashim-io/datashim)

This component is compatible with Fybrik v1.0.

## Setup for Using this Component

### Priveleges

Ensure that the pipeline has the appropriate RBAC priveleges to create the FybrikApplication from the pipeline.

```bash
kubectl apply -f rbac_resources.yaml -n kubeflow
```

### Storage for Write and Copy Flows

Register a storage account in which the results can be written.  Example files are provided called kfp-storage-secret.yaml and kfp-storage-account.yaml.  Please change the values in these files with storage endpoint and credential details.  

Note: Make sure that the endpoint you provide includes the protocol prefix, example `https://`, because otherwise datashim will not work.

```
kubectl apply -f kfp-storage-secret.yaml -n fybrik-system
kubectl apply -f kfp-storage-account.yaml -n fybrik-system
```

Fybrik documentation has more details about how to [create an account in object storage](https://fybrik.io/v1.1/samples/notebook-write/#create-an-account-in-object-storage)
and [how to deploy resources for write scenarios](https://fybrik.io/v1.1/samples/notebook-write/#deploy-resources-for-write-scenarios).  The Fybrik examples create two storage accounts, but in our example one is sufficient.

## Usage

This component receives the following parameters, all of which are strings.

Input:

* train_dataset_id -  data catalog ID of the dataset on which the ML model is trained
* test_dataset_id - data catalog ID of the dataset containing the testing data

Outputs:

* train_endpoint - virtual endpoint used to read the training data
* test_endpoint - virtual endpoint used to read the testing data
* result_endpoint - virtual endpoint used to write the results

### Example Pipeline Snippet

```python
def pipeline(
    test_dataset_id: str,
    train_dataset_id: str
):
       
    # Where to store parameters passed between workflow steps
    result_name = "submission-" + st(run_name)

    # Default - could also be read from the environment
    namespace = kubeflow
    
    # Get the ID of the run.  Make sure it's lower case and starts with a letter 
    run_name = "run-" + dsl.RUN_ID_PLACEHOLDER.lower()

    getDataEndpointsOp = components.load_component_from_file(
        'https://github.com/fybrik/kfp-components/blob/master/get_data_endpoints/component.yaml') 

    getDataEndpointsStep = getDataEndpointsOp(
        train_dataset_id=train_dataset_id, 
        test_dataset_id=test_dataset_id, 
        namespace=namespace, 
        run_name=run_name, 
        result_name=result_name)

    #...

    trainModelOp = components.load_component_from_file(
        './train_model/component.yaml')
    trainModelStep = trainModelOp(
        train_endpoint_path='%s' % getDataEndpointsStep.outputs['train_endpoint'],
        test_endpoint_path='%s' % getDataEndpointsStep.outputs['test_endpoint'],
        result_name=result_name,
        result_endpoint_path='%s' % getDataEndpointsStep.outputs['result_endpoint'],
        train_dataset_id=train_dataset_id,
        test_dataset_id=test_dataset_id,
        namespace=namespace)
```

## Development

If you wish to enhance or contribute to this component, please note that it is 
written in python and packaged as a docker image.

To build the docker image use:

```bash
sh build_image.sh
```
