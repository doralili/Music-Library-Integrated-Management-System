# 数据库初始化文件使用操作步骤

**前置说明**：项目已上传完成 `project\_init\.sql` 初始化文件，无需自行创建、修改文件，仅按照以下步骤执行，即可完成数据库环境统一初始化，适配项目全部功能（含音频自动时长识别、曲风筛选、歌单管理）。

**前置环境**：已安装 WSL2、Docker、openGauss 容器，且已创建 `music` 数据库

### 步骤1：进入项目根目录（必做）

打开 WSL2 终端，执行以下命令定位到项目文件夹，所有后续操作必须在此目录下执行：

```Plain Text
cd /mnt/c/Users/82582/Desktop/Music-Library-Integrated-Management-System（按照实际情况填写）
```

### 步骤2：将SQL文件上传至数据库容器

执行以下命令，将仓库中的初始化文件同步到 openGauss 容器内，无终端输出即为执行成功：

```Plain Text
docker cp project_init.sql my_opengauss:/tmp/
```

### 步骤3：登录openGauss数据库

依次执行以下命令进入数据库环境，出现 `music=\#` 提示符即为登录成功：

```Plain Text
docker exec -it my_opengauss bash
su - omm
gsql -d music -U omm -W Axmo@9830 -p 5432
```

### 步骤4：一键执行数据库初始化

在 `music=\#` 状态下执行以下命令，自动创建所有数据表、适配项目全部字段：

```Plain Text
\i /tmp/project_init.sql
```

**执行成功标准**：终端依次输出以下内容

> CREATE TABLE
> CREATE TABLE
> CREATE TABLE
> INSERT 0 1
> 
> 

### 步骤5：退出数据库及容器

初始化完成后，依次执行命令退出环境：

```Plain Text
\q
exit
exit
```

### 步骤6：安装项目依赖并启动项目

安装包含音频时长识别插件在内的全部依赖：

```Plain Text
pip install -r requirements.txt --break-system-packages
```

启动项目：

```Plain Text
streamlit run app.py
```

## 常见问题快速排查

1. **报错：No such file or directory**：未正确进入项目根目录，重新执行步骤1定位文件夹

2. **SQL执行找不到文件**：重新执行步骤2上传SQL文件，核对文件名无误

3. **音频时长识别失效**：重新执行依赖安装命令，确保 mutagen、pydub 库安装成功

4. **提示数据表已存在**：脚本自带重复执行兼容，无需处理，不影响项目运行和数据


