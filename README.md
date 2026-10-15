# 提交时不要直接提交到主分支 main
## 更新 main
```
git pull
```

## 创建分支
> `your_branch` 是你自定义的分支名

```
git branch your_branch
```

## 切换分支
```
git checkout your_branch 
```
## 检查是否切换成功
```
git status
```
> 输出 `On branch your_branch` ，就是成功了
## 提交代码
```
git push
```
> 如果报错 `The current branch your_branch has no upstream branch` ，使用下面这条命令提交
```
git push --set-upstream origin your_name
```