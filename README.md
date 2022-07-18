# GitHub self-hosted runner 配置说明

## 下载 self-hosted runner

进入仓库 Settings - Actions - Runners，根据提示创建新的 runner，操作系统选择 Linux，架构选择 x64，根据提示给出的命令下载 actions-runner 客户端软件。

此说明以 `2.294.0` 版本为例：

```shell
mkdir actions-runner

curl -o actions-runner-linux-x64-2.294.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.294.0/actions-runner-linux-x64-2.294.0.tar.gz

echo "a19a09f4eda5716e5d48ba86b6b78fc014880c5619b9dba4a059eaf65e131780  actions-runner-linux-x64-2.294.0.tar.gz" | shasum -a 256 -c

cd actions-runner

tar xzf ../actions-runner-linux-x64-2.294.0.tar.gz
```

（以上命令与 GitHub 提示的命令不完全一致，差别体现在以上版本解压好的 `actions-runner` 目录下不含有压缩包）

## 构建 Docker 镜像并配置 Runner

首先需要建立好一个含有 [评测脚本](https://github.com/Meow-Twice/sysy-test) 的镜像，名称为 `sysy-test:latest` ，然后根据本目录下的 Dockerfile 继续构建 runner 镜像，在构建镜像过程中自动运行 runner 配置。

配置 runner 所需参数需通过 `docker build` 命令的 `--build-arg` 选项传入，也可直接使用提供的 `docker-build.sh` 脚本。

交互方式 (根据提示输入相应参数):

```
$ ./docker-build.sh
[URL of the git repo]:https://github.com/Meow-Twice/Meow-Compiler
[Token to add runner]:XXXXXXXXXXXXXXXXXX
[Runner name (default hostname)]:sysy-action-runner
```

非交互方式 (通过环境变量直接传入参数):

```
$ URL=https://github.com/Meow-Twice/Meow-Compiler TOKEN=XXXXXXXXXXXXXXXXXX NAME=sysy-action-runner ./docker-build.sh
```

所有构建并配置的 runner 镜像均带有标签 `sysy-runner`，可在 Action Workflow 文件中使用该标签以标识 runner。

## 运行 action runner

action runner 镜像基于评测脚本构建，部署 runner 的主机需事先装载好测试用例集，并创建好相应目录(通过 `-v` 选项挂载至容器内)以存放: 

- 编译器源代码
- 编译器构建成品
- 测试用例
- 评测结果

以下给出一组示例 (格式 `主机路径:容器路径[:选项]`，与 `-v` 选项传入的参数格式相同)：

- 配置文件(只读挂载)
  - 如只有一个配置文件，可挂载单个文件 `/home/ubuntu/compiler/config.json:/app/config.json:ro`
  - 如有多个配置文件，也可挂载配置目录 `/home/ubuntu/compiler/configs/:/home/git/configs/:ro`
- 测试用例集(只读挂载) `/home/ubuntu/compiler/testcase/:/home/git/testcase/:ro`
- 编译器源代码 `/home/ubuntu/compiler/src/:/home/git/compiler/src/`
- 编译器构建成品 `/home/ubuntu/compiler/build/:/home/git/compiler/build/`
- 评测结果 `/home/ubuntu/compiler/logs/:/home/git/logs/`

除此以外，由于评测脚本用到 docker in docker，因此还需将主机的 `/var/run/docker.sock` 挂载至容器内相同路径。

评测脚本配置文件示例 (实际使用时需去掉注释)：

```jsonc
{
    "compiler-src": "/home/ubuntu/compiler/src",        // 编译器源代码的主机路径
    "compiler-build": "/home/ubuntu/compiler/build",    // 编译器构建品的主机路径
    "testcase-base": "/home/git/testcase",              // 测试用例的容器路径
    "testcase-select": ["functional", "performance"],
    "num-parallel": 8,
    "timeout": 60,                                      // 超时时间，可根据实际情况酌情上调
    "rebuild-compiler": true,                                 
    "jvm-options": "",
    "run-type": "rpi-elf",                                             
    "rpi-address": "http://192.168.1.2:9000",
    "log-dir": "/home/git/logs",                        // 测试结果的容器路径
    "log-dir-host": "/home/ubuntu/compiler/logs",       // 测试结果的主机路径
}
```

启动 runner:

```shell
# ensure the owner of these directories is not root
mkdir -p /home/ubuntu/compiler/src/ /home/ubuntu/compiler/build/ /home/ubuntu/compiler/logs/
# use --stop-signal=SIGINT to gracefully stop the action runner process
docker run -d --name=sysy-action-runner --restart=unless-stopped --stop-signal=SIGINT \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /home/ubuntu/compiler/testcase/:/home/git/testcase/:ro \
    -v /home/ubuntu/compiler/configs/:/home/git/configs/:ro \
    -v /home/ubuntu/compiler/src/:/home/git/compiler/src/ \
    -v /home/ubuntu/compiler/build/:/home/git/compiler/build/ \
    -v /home/ubuntu/compiler/logs/:/home/git/logs/ \
    sysy-action-runner:latest
```

（以上示例中的**主机目录**在部署时请根据实际情况替换，推荐将替换好的命令保存为一个 `.sh` 文件存储在本地）