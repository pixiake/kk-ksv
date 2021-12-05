package pipelines

import "github.com/kubesphere/kubekey/pkg/common"

func PreCheck(args common.Argument) error {
	var loaderType string
	if args.FilePath != "" {
		loaderType = common.File
	} else {
		loaderType = common.AllInOne
	}

	runtime, err := common.NewKubeRuntime(loaderType, args)
	if err != nil {
		return err
	}

	switch runtime.Cluster.Kubernetes.Type {
	case common.K3s:
		if err := NewK3sPreCheckPipeline(runtime); err != nil {
			return err
		}
	default:
		return nil
	}

	return nil
}

func NewK3sPreCheckPipeline(runtime *common.KubeRuntime) error {

	return nil
}
