# Terraform + CodePipeline + EKS

Este projeto tem como objetivo demonstrar a automação e a Infraestructure-as-code (IaC), de um projeto proivisionado totalmente na AWS, utilizando seus recursos de forma pratica e explicita. Neste projeto abordaremos o Terraform, armazenando seus arquivos no S3, e provisionando totalmente a infra necessária para que a aplicação execute perfeitamente, além disto, utilizaremos os recursos do CodePipeline e CodeBuild, para fazer a automatização dos builds, teste e deployments de nossa aplicação.

Essa aplicação será provisionada a partir de um EKS - Kubernetes Cluster, que será criada pelo nosso arquivo do Terraform. Todos os passos necessários para a execução deste projeto estão descritos abaixo. Caso deseje ter um conhecimento mais a fundo do Terraform e da AWS e seus recursos, recomendo que leia a documentacao de ambas as plataformas.

Para aplicarmos completamente todos os passos necessarios para que o projeto execute corretamente, siga os seguintes passos:

1. [TerraForm](#Terraform)
    - [Serviços](#TfServices)
    - [Infra-Estrutura](#TfInfra)
2. [AWS](#AWS)
    - [CodePipeline](#AWSCP)
    - [CodeBuild](#AWSCB)
    - [EKS](#AWSEKS)
3. [Kubernetes](#Kubernetes)
    - [Ingress Nginx](#K8SIN)
    - [Storage Class](#K8SSC)
    - [MongoDB](#K8SMDB)
    - [Aplicação](#K8SA)
4. [Aplicação](#Application)
5. [Consideracoes Finais](#LastComment)

#Terraform
---
## TerraForm
---

Neste projeto optamos pela utilizaçao do TerraForm (IaC), pela práticidade e facilidade que temos com ele. Por ter sido projeto para se utilizar com equipes de grandes de desenvolvimento, trabalhando todos os processos necessários para este tipo de ação, ele conta com sistema de Lock, quando necessário, com armazenamento de suas configurações em nuvem, tendo toda a gestão para evitar falhas gerenciadas por ele.

Este projeto do TerraForm foi organizado na seguinte maneira:

```
Terraform/
    |- Global/ -> Reponsável por armazenar todos os recursos que são globais do projeto.
    |    |- main.tf -> Criação de Bucket e DynamoDB
    |- Infraestructure/ -> Responsável por armazenar toda a infraestrutura necessária para a aplicação executar.
    |    |- Development/ -> Infraestrutura do ambiente de Desenvolvimento.
    |    |    |- vpc/ -> Responsável por criar a VPC necessária para os recursos deste ambiente.
    |    |- Production/ -> Infraestrutura do ambiente de Production.
    |- Modules/ -> Responsável por armazenar todos os arquivos de Modulos, que são reaproveitados quando necessários.
    |    |- CodeBuild/ -> Responsável por criar o CodeBuild das aplicações deste projeto.
    |    |- CodePipeline/ -> Responsável por criar o CodePipeline das aplicações deste projeto.
    |    |- ECR/ -> Responsável por criar o ECR das aplicações deste projeto.
    |    |- Kubernetes-Cluster/ -> Responsável por criar o Kubernetes que será usado neste projeto.
    |    |- Route53/ -> Responsável por criar zonas de DNS para serem utilizadas neste projeto.
    |    |- ACM/ -> Responsável por criar os certificados utilizados por este projeto.
    | Services/ -> Responsável pela geração dos serviços em cada ambiente necessário deste projeto.
    |    |-  Development/ -> Serviços do ambiente de Desenvolvimento.
    |    |-  Production/ -> Serviços do ambiente de Produção.
```
> Foram cortados os arquivos *variables.tf*, *outputs.tf*, *main.tf*, pois todos consistem na mesma abordagem: Entrada de valores, saída de valores e criação de recursos.

Utilizamos o Backend "S3", para armazenarmos os arquivos TF States, gerados em todos os momentos que é feito algum _terraform apply_, para que em qualquer momento tenhamos acesso a estes arquivos, e dessa forma o TerraForm possa controlar todos os recursos que já foram criados por ele.

Utilizamos também o DynamoDB, para fazermos a gestão dos Locks que o TerraForm necessita. Estes Locks, servem para o caso de termos 2 equipes executando um *apply*, do mesmo TF File, no mesmo instante, o que poderia gerar problemas e assim ambos os *apply* falharem ou duplicarem a infra. Estes Locks, bloqueiam a execução de um *apply* simultâneo.

Todos esse primeiro processo do Backend "S3" e o DynamoDB, está codificado em um TF File deste repositório, que está na pasta *TerraForm/Global*. Para executarmos esse TF File, e provisionar a infraestrututa inicial para o TerraForm e todo o conjunto codificado neste projeto, será necessário configurarmos três variáveis de ambiente neste projeto, sendo elas descritas abaixo:

```
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
export AWS_DEFAULT_REGION=""
```

Estas variáveis de ambiente são responsável por conceder o acesso a AWS e permitir ao TerraForm criar e gerenciar os recursos na nuvem. Para obter essas credenciais é necessário seguir o seguinte tutorial: [AWS IAM](https://docs.aws.amazon.com/pt_br/general/latest/gr/managing-aws-access-keys.html).

Por padrao este projeto esta configurado para criar um bucket com o nome __*terraform-state-files-hotmart*__, caso deseje mudar o nome do Bucket ou caso de erro na criacao por duplicidade no nome do Bucket, recomendo que edit os arquivos __*main.tf*__, das pastas *Infraestructure/(Development/Production)* e *Services/(Development/Production)*, na tag __*Terraform{ backend "s3" {}}*__ para o novo nome de Bucket desejado.

Após a configuração necessária para o TerraForm acessar a AWS, será necessária a execução de dois comandos TerraForm, sendo eles:

```
terraform init  -> Responsável por baixar e preparar todas as dependências do TerraForm.
terraform apply -auto-approve -> Responsável por criar e gerenciar toda a infraestrutura descrita em cada arquivo TF.
```
> Estes comandos devem ser executados dentro da pasta principal de cada Serviço/InfraEstrutura. No caso acima, será necessário executar este comando na pasta *Terraform/Global*

Ao finalizar a execução de ambos os comandos, será criado um Bucket S3 para armazenar todos os arquivos Tf State, e uma tabela no Dynamo DB para fazer a gestão de cada Locks.

#TfServices
### Serviços

Nesta etapa já estamos prontos para criarmos os serviços necessários para a automação de Build deste aplicação. Dentro da pasta *Services/Development* ou *Services/Production*, existe um arquivo *main.tf* que é responsável por agrupar todos os recursos necessários, junto com os recursos existem alguns valores que podem ser modificados, para criar ambientes diferentes sempre que necessário, esses valores estão descritos dentro da tag __*locals { }*__, pela qual armazena todas as configurações locais deste Tf File, desta forma caso queira mudar algo para sua infraestrutura gerada, recomendo que modifique neste arquivo.

Para que ocorra tudo perfeitamente com a criação do CodeBuild e seu processo de automação, é necessário que seja feita uma configuração na tag __*locals { }*__, que consiste em modificar a chave: __*OAuthToken*__. Essa chave é reponsável por permitir o acesso ao repositório e ao WebHook, entre o GitHub e o AWS CodePipeline, sem a criação deste Token, não será possível do AWS CodePipeline acessar os arquivos no repositório. Para criar o __*OAuthToken*__ no GitHub, segue o tutorial: [GitHub](https://docs.cachethq.io/docs/github-oauth-token).

Para iniciar o processo de criação dos serviços é necessário executar os seguintes comandos:

```
terraform init  -> Responsável por baixar e preparar todas as dependências do TerraForm.
terraform apply -auto-approve -> Responsável por criar e gerenciar toda a infraestrutura descrita em cada arquivo TF.
```
> Estes comandos devem ser executados dentro da pasta principal de cada Serviço/InfraEstrutura. No caso acima, será necessário executar este comando na pasta *Terraform/Serviços/__(Development/Production)__*, de acordo com qual ambiente deseja provisionar.

Após a finalização da criação dos recursos, será armazenado um arquivo TF State no Backend "S3".

#TfInfra
### Infra-Estrutura

Após a criação de todos o processo de Build automatizado, iremos criar a arquitetura necessária para que nossa aplicação seja provisionada. Nesta etapa optamos por utilizar o EKS, pela questão da segurança, praticidade e compatibilidade com os recursos da AWS, além de nos prover uma rápida escalabilidade e uma alta disponibilidade.
 
Para isso optamos por criar uma VPC exclusiva para o EKS e seus workers, sendo divididas em 4 Subnets, sendo 2 delas para operar junto com o EKS Cluster Principal e outra para operarmos com seus Node Group. Optamos por utilizar uma VPC com acesso a internet, para facilitar o gerenciamento do Cluster, entretanto é altamente recomendado que seja configurado um Cluster, que tenha 2 subnets privadas e 2 subnets públicas, para que sejam utilizados de acordo com a necessidade do serviço, podendo ser um serviço que não necessite acesso externo ou um serviço que necessite de um acesso externo. Por mais que o EKS tenha um rede interna, muitas vezes é necessário que outros serviços dentro da rede tenha acesso a ele e com isso foi criado uma regra de firewall para fazer a gerencia do que pode e não pode trafegar para o EKS.
 
Criado o EKS, é necessário que seja criado o Node Group(Workes), para que tenhamos os recursos necessário para prover nossa aplicação. Cada Node Group é necessário que sejam selecionados as Instancias EC2 desejada, as subnets que serão utilizadas pelas instâncias, e o tamanho desejado de workers, sendo configurado por *desejado*, *máximo*, *mínimo*. Feitas todas essas configurações seu Node Group estará pronto para ser utilizado, e seu EKS também estará pronto para prover aplicações.
 
Neste projeto temos os arquivos TF Files necessários para criarmos automaticamente todo o EKS, sendo desde a parte do VPC, Node Group e Route53. Dentro da pasta *Infraestructure/(Development/Production)*, existe um arquivo *main.tf* que é responsável por agrupar todos os recursos necessários, junto com os recursos existem alguns valores que podem ser modificados, para criar ambientes diferentes sempre que necessário, esses valores estão descritos dentro da tag __*locals { }*__, pela qual armazena todas as configurações locais deste Tf File, desta forma caso queira mudar algo para sua infraestrutura gerada, recomendo que modifique neste arquivo. Caso deseje modificar o VPC gerado, é necessário modificar apenas o *main.tf* que está dentro da pasta *Infraestructure/(Development/Production)/vpc*.
 
Optamos por criar automaticamente o Route53, sendo ele gerado a partir dos valores configurados para a criação do EKS. O DNS criado teria o nome: *{cluster_name}-{environment}.{aws_region}.com*, gerando também os certificados WildCard pelo Certificate Manager, ficando **.{cluster_name}-{environment}.{aws_region}.com*. Este DNS criado, será utilizado para o acesso a aplicação.
 
Para iniciar o processo de criação dos serviços é necessário executar os seguintes comandos:
 
```
terraform init  -> Responsável por baixar e preparar todas as dependências do TerraForm.
terraform apply -auto-approve -> Responsável por criar e gerenciar toda a infraestrutura descrita em cada arquivo TF.
```
> Estes comando devem ser executados dentro da pasta principal de cada Serviço/InfraEstrutura. No caso acima, será necessário executar este comando na pasta *Terraform/Infraestructure/__(Development/Production)__*, de acordo com qual ambiente deseja provisionar.
#AWS
---
## AWS
---
 #AWSCP
### CodePipeline
 
Optamos por utilizar o CodePipeline pela praticidade de integração com todos os recursos da AWS, e fácil integração com o source de nosso projeto, que está hospedado no GitHub. Para utilizarmos ele, usamos o WebHook do GitHub para disparar os Build de forma automatizada, sempre que ocorrer algum push no projeto. Junto com ele utilizamos o CodeBuild, para prover todo o Build automático de nosso projeto.
 
O CodePipeline é responsável por gerenciar todo o pipeline de nosso projeto e dessa forma unir todos os outros recursos de desenvolvimento da AWS em uma única plataforma, facilitando todo o processo de gerência e análise. Podemos utilizar o CodeCommit, GitHub, S3, etc, como repositórios de códigos, e ao subir algum arquivo o CodePipeline iniciaria o processo de build. Dessa forma é uma ferramenta poderosa, quando se usado nos ambientes da AWS.
 
Para o processo de build, optamos por utilizar o CodeBuild, pela praticidade na integração com o CodePipeline e os recursos da AWS. É necessário apenas escrever um arquivo *buildspec.yml* no projeto e definir todos os passos necessários para o processo de build da aplicação.
> Este arquivo *buildspec.yml* está definido no root deste repositório, por questões de praticidade. Nas considerações finais, terá uma overview de toda organização deste repositório.

#AWSCB
#### CodeBuild
 
Para configuração do CodeBuild, optamos por configurar uma máquina mais lenta para o ambiente de *development* e uma máquina mais poderosa para o ambiente de *production*, por questões de custo. É possível configurar uma rede VPC, para que o CodeBuild tenha acesso a rede interna da AWS, porém optamos por não configurar, pela não necessidade de acesso a alguma aplicação interna.

#AWSEKS
### EKS
 
Optamos pela utilização do EKS para este projeto, graças a sua escalabilidade, alta disponibilidade, divisão de responsabilidade e __segurança__.

#Kubernetes
## Kubernetes
 
O Kubernetes e uma poderosa ferramenta de orquestração de containers, com ela podemos organizar os recursos da melhor maneira e ainda criar *réplicas* de nossas aplicações, para caso ocorra algum desastre a aplicação não fique fora do ar. Além disso, é uma das ferramentas com maior contribuição do GitHub, sendo uma comunidade forte e ativa de desenvolvimento. É possível também desenvolver plugins e serviços, que rodam junto ao Kubernetes e assim automatizar ainda mais todo o ambiente, e um desses exemplos seria o Ingress (Nginx ou ALB), cert-manager(Geração de Certificado Válidos), replicator(Réplica secrets), etc. Ao se utilizar todos os recursos que o Kubernetes nos provê, é possível ter uma infraestrutura pequena, porem com todos os recursos necessários para se executar uma aplicação perfeitamente.
 
Neste projeto, optamos por deixar o EKS fazer toda a gestão de recursos na nuvem necessárias para que a aplicação execute com segurança e escalabilidade. Dessa forma, optamos por utilizar um Ingress Nginx, no lugar de um ALB, pela questão de praticidade de se aplicar esse recurso e principalmente pela questão de custo que teríamos ao utilizar. Um ALB tem um custo fixo mensal de $25 e ainda existe um custo variável que ocorre de acordo com a quantidade de dados trafegados e a quantidade de requisições por mês, dessa forma poderia deixar um projeto pequeno inviável. O Ingress Nginx utiliza os recursos das próprias máquinas do Kubernetes, e por necessitar de um processamento baixo e de pouca memória, faz com que o custo com essa aplicação seja pequena, e ela funcione perfeitamente nestes casos de uso. Uma vantagem do ALB, seria a utilização de TCP (Secure), o que o Ingress Nginx não atenderia as especificações, portanto sempre recomendo analisar muito bem quais as necessidades dos serviços que serão providos pelos ingressos.
 
Os arquivos Kubernetes deste projeto estão armazenados na pasta *Kubernetes/*, eles estão divididos em dois conjuntos *Kubernetes/Application* e *Kubernetes/Services*. Segue uma explicação detalhada de cada pasta:
 
```
Kubernetes/
    |- Application/ -> Responsável por armazenar todos os arquivos yaml das aplicações deste projeto.
    |    |- FrontEnd/ -> Arquivos yaml do FrontEnd.
    |    |- BackEnd/ -> Arquivos yaml do BackEnd.
    |- Services/ -> Responsável por armazenar toda a infraestrutura de serviços necessários para a aplicação executar.
    |    |- Ingress-Nginx/ -> Arquivos yaml do Ingress Nginx.
    |    |- MongoDB/ -> Arquivos yaml do MongoDB.
```
 
Responsabilidade de cada arquivo Yaml da aplicação:
 
```
Kubernetes/
    |- namespace.yaml -> Responsavel pela criacao do namespace.
    |- configmap.yaml -> Responsavel pela criacao do configmap.
    |- services.yaml -> Responsavel pela criacao do services da aplicação(NodePort, ClusterIP ou LoadBalancer).
    |- deployment.yaml -> Responsável pela criação do deployment da aplicação.
    |- ingress.yaml -> Responsável pela geração do Ingress da aplicação.
```
> Obs1: Os arquivos contêm uma sequência de números iniciais como por exemplo *00-*, para que sejam aplicados na ordem certa, e haja uma organização. Como um arquivo yaml, pode depender do recurso existente no outro, e altamente recomendado que seja organizado desta forma.
 
> Obs2: Optamos por não criar o arquivo de *secrets.yaml* e manter no repositório por questão de segurança. É altamente recomendado que seja utilizado um serviço de secrets dinâmico, como secret manager, vault, etc, para que as secrets fiquem armazenadas em um local seguro e com acesso restrito. 
 
A todo momento em que for feito uma Build nova da aplicação estaremos aplicando esses arquivos do Kubernetes, para atualizarmos as configurações de cada recurso do EKS.
 
Para provisionar essa aplicacao de maneira manual, sem o CodeBuild aplicar os arquivos yaml, é necessário executar apenas um comando. Segue o comando abaixo:
 
```
kubectl apply -f . -> Irá aplicar todos os arquivos Yaml de seu diretório atual.
```
> É necessário estar dentro da pasta que deseja aplicar os arquivos ou trocar o __*.*__ pela pasta de destino dos arquivos Yaml, que deseja aplicar.

#K8SIN
### Ingress Nginx
 
Para utilizarmos o Ingress Nginx criamos um LoadBalancer de Layer 7(ALB), o objetivo deste LoadBalancer seria para as requisições possam chegar aos servidores web corretamente, de acordo com as requisições. Para criarmos os recursos necessários para o Kubernetes reconhecer o Ingress Nginx e ele funcionar como um Application Gateway, e necessário aplicar seus arquivos yaml, estes arquivos estão dentro da pasta *Kubernetes/Services/Ingress-Nginx*. Comando necessário para aplicar:
 
```
kubectl apply -f . -> Irá aplicar todos os arquivos Yaml de seu diretório atual.
```
> É necessário estar dentro da pasta *Kubernetes/Services/Ingress-Nginx* ou trocar o __*.*__ por __*Kubernetes/Services/Ingress-Nginx*__.
 
Após aplicarmos corretamente os arquivos de configuração do Ingress Nginx e o LoadBalancer estiver criado corretamente, teremos um acesso às aplicações que estiverem hospedadas no Kubernetes, sendo necessário apenas configurar no DNS para apontar para o DNS do LoadBalancer criado.
 
Essa parte de apontamento do DNS do LoadBalancer no Route53, deverá ser feita manualmente, pois essa parte ainda não está automatizada neste processo. Uma forma de automatizar esse processo seria criando um serviço que rodaria junto ao Ingresso e ele automaticamente registraria no Route53 a todo momento que for criado um novo Ingress no Kubernetes, dessa forma seria necessário apenas a criação do Ingress, sem a necessidade de criar no Route53, em *Python* uma aplicação deste porte seria feita rapidamente, recomendo que leia sobre a documentacao do [Boto3](https://github.com/boto/boto3) e [Kubernetes-Client Python](https://github.com/kubernetes-client/python), em outro momento irei criar um repositório com a aplicação que gerencia essa parte.
 
Com este poderoso LoadBalancer, poderemos configurar uma duas aplicações respondendo para a mesma URL, porém apontando para locais diferentes, como por exemplo: *https://application.onredes.com* (FrontEnd) - *https://application.onredes.com/api* (BackEnd). Utilizando essa ferramenta podemos diminuir os custos de nossas aplicações.

#K8SSC
### Storage Class
 
Ao se trabalhar com o Kubernetes em um provider, e principalmente ao termos o EKS, podemos configurar facilmente a criação de storages quando necessário, para isso é necessário criar classes de Storage, existem algumas que são criadas por padrão, como por exemplo *local*, porém algumas são necessárias criar manualmente, pela quantidade de opções que podemos ter.
 
Neste caso optamos por criar duas classes essencialmente, são elas *slow* e *fast*, essas classes definem qual o tipo de armazenamento que será utilizado para armazenar os arquivos das aplicações. Uma forma muito utilizada para isso e para os bancos de dados, como por exemplo *MongoDB* que necessita de um banco de dados de IOPs alto, e ao selecionarmos o Storage Class correto, temos ganho em performance e tudo ocorre de forma automatizada.
 
Para aplicarmos os arquivos de configuração do Storage Class, é necessário executar os seguintes comandos:
 
```
kubectl apply -f . -> Irá aplicar todos os arquivos Yaml de seu diretório atual.
```
> É necessário estar dentro da pasta *Kubernetes/Services/Storage-Class* ou trocar o __*.*__ por __*Kubernetes/Services/Storage-Class*__.

#K8SMDB
### MongoDB
 
Nossa aplicação necessita de um banco de dados MongoDB para que se provisione corretamente a aplicação. Para isso utilizaremos o Addons do tipo StatefulSet, pela questão de ser um banco de dados de alta disponibilidade e de fácil configuração, unido ao poder do StatefulSet, temos um banco completamente configurado e de alta disponibilidade. Para conhecer mais sobre os [StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/).
 
Para aplicar e criar o banco de dados MongoDB, é necessário executar os seguintes comandos: 
 
```
kubectl apply -f . -> Irá aplicar todos os arquivos Yaml de seu diretório atual.
```
> É necessário estar dentro da pasta *Kubernetes/Services/MongoDB* ou trocar o __*.*__ por __*Kubernetes/Services/MongoDB*__.

#K8SA
### Aplicação
 
Para criarmos os recursos da aplicação no Kubernetes e necessário aplicarmos os arquivos YAML que estão dentro do folder *Application/(FrontEnd/BackEnd)*, estes arquivos irão criar os configmaps, namespaces, serviços, deployments e ingress. Como dito acima optamos por não colocar os secrets no repositório por questão de segurança, por isso será necessário criar manualmente os arquivos. Para isso execute os comandos abaixo:
 
```
kubectl create secret generic -n application backend-user
kubectl edit secret -n application backend-user
```
> Optamos por criar a secret e depois modificá ela pela facilidade que teríamos utilizando um editor de texto simples, do que linha de comando. Como a Secret utiliza Base64 para armazenar suas informações, este processo se torna oneroso se fizermos por linha de comando diretamente.
 
Um importante ponto a ser analisado está nas configurações de imagens do kubernetes, o arquivo YAML de Deployment está configurado para a imagem __*.*__ (pelo qual nao existe), porem ao passar pelo CodeBuild será feito a correção e o deployment seria corrigido com a imagem correta, gerada pelo CodeBuild. Caso deseje pode modificar o arquivo YAML de Deployment para o repositório de imagem correto, o repositório foi gerado automaticamente junto ao CodeBuild e se encontra no ECR, lembre-se de colocar o repositório correto em cada aplicação.

#Application
---
## Aplicação
---
 
Este projeto não tem como foco a aplicação feita, apenas demonstrar o processo de provisionamento de uma InfraEstrutura, utilizando a AWS, EKS e o TerraForm, sera dada apenas uma explicação rapida e simples deste projeto. Este projeto foi selecionado pelo fato de ser uma aplicação que contém FrontEnd, BackEnd e um Banco de Dados, que simula muito bem uma aplicação simples. Ele contém um FrontEnd estático, provisionado por uma imagem Docker proveniente de uma imagem do [Nginx](https://hub.docker.com/_/nginx), e um BackEnd, provisionado por uma imagem Docker proveniente de uma imagem do [NodeJS](https://hub.docker.com/_/node), fazendo o processo de Build e automatização de maneira pratica e facil.
 
Para o build do FrontEnd, optamos por utilizar uma imagem Docker com o NodeJS, porém existem outras formas mais práticas para fazermos esse processo, uma delas seria o CodeBuild buildar o código em React e o Docker utilizar apenas o código Buildado, neste processo ganhamos o poder de facilitar o Build, pois ao utilizarmos o Build por Environment Variable podemos ter problemas ao setar essas variáveis dentro do Build do Docker, podendo se tornar um processo oneroso, o que quando colocamos buildando no CodeBuild diretamente e não no docker, não corre.

Para que esta aplicacao funcione corretamente, e necessario que se tenha as seguintes variaveis de ambiente:

```
SECRET_OR_KEY - Reponsavel pela Secret Key utilizada pelo JWT. (Secret)
SERVER_TYPE - Selecionar o formato que ia ser executado a aplicacao. (Configmap)
MONGO_URI - URI do Banco de dados do MongoDB (mongodb://). (Secret)
URL_BASE - URL Base da aplicacao. (Configmap)
NODE_ENV - Environment da aplicacao. (Configmap)
PORT - Porta pelo qual ira rodar. (Configmap)
```
#LastComment
---
## Consideracoes Finais
---

Todo este projeto esta automatizado para utilizar como Infraestructure-as-Code, sendo necessario apenas o apply inicial, para que seja provisionado toda a automacao desejada. Este apply inicial pode ser feito a partir do build do Dockerfile existente dentro da pasta *Terraform/*, dessa forma facilita a configuracao inicial da aplicacao.

O BuildSpec deste projeto foi feito pensando que todos os arquivos estariam no mesmo repositorio, porem foi desenhado ja pensando no caso de termos de criar repositorios fixos para o Terraform, Kubernetes e a Application, como o contexto pode mudar e aplicacoes tendem a aumentar de tamanho, temos sempre de imaginar em como escalar determinado projeto, e dessa forma fica facil escalar todo o necessario.