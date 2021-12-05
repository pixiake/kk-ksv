/*
Copyright © 2021 NAME HERE <EMAIL ADDRESS>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
package cmd

import (
	"github.com/kubesphere/kubekey/cmd/ctl/options"
	"github.com/kubesphere/kubekey/cmd/ctl/util"
	"github.com/kubesphere/kubekey/pkg/common"
	"github.com/pixiake/kk-ksv/pkg/pipelines"

	"github.com/spf13/cobra"
)

type PreCheckOptions struct {
	CommonOptions *options.CommonOptions

	ClusterCfgFile string
}

func NewPreCheckOptions() *PreCheckOptions {
	return &PreCheckOptions{
		CommonOptions: options.NewCommonOptions(),
	}
}

// NewCmdPeCheck represents the preCheck command
func NewCmdPeCheck() *cobra.Command {
	o := NewPreCheckOptions()
	cmd := &cobra.Command{
		Use:   "preCheck",
		Short: "Pre-check the environment",
		Run: func(cmd *cobra.Command, args []string) {
			util.CheckErr(o.Run())
		},
	}

	o.CommonOptions.AddCommonFlag(cmd)
	o.AddFlags(cmd)

	return cmd
}

func (o *PreCheckOptions) Run() error {
	arg := common.Argument{
		FilePath: o.ClusterCfgFile,
	}

	return pipelines.PreCheck(arg)
}

func (o *PreCheckOptions) AddFlags(cmd *cobra.Command) {
	cmd.Flags().StringVarP(&o.ClusterCfgFile, "filename", "f", "", "Path to a configuration file")
}
