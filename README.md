# Terraform + CodePipeline + EKS
 
Este projeto tem como objetivo demonstrar a automação e a Infraestructure-as-code (IaC), de um projeto provisionado totalmente na AWS, utilizando seus recursos de forma prática e explicita. Neste projeto abordaremos o Terraform, armazenando seus arquivos no S3, e provisionando totalmente a infra necessária para que a aplicação execute perfeitamente, além disto, utilizaremos os recursos do CodePipeline e CodeBuild, para fazer a automatização dos builds, teste, deployments, e provisão de recursos na nuvem.
 
Essa aplicação será provisionada a partir de um EKS - Kubernetes Cluster, que será criada pelo nosso arquivo do Terraform. Todos os passos necessários para a execução deste projeto estão descritos abaixo. Caso deseje ter um conhecimento mais a fundo do Terraform e da AWS e seus recursos, recomendo que leia a documentação de ambas as plataformas.

As regras necessárias para criar cada recurso, estão descritas no final desta documentação, atualmente estamos utilizando a política *AdminAccess* para facilitar a criação, porém é altamente recomendado que seja utilizado as políticas descritas abaixo.
 
Para aplicarmos completamente todos os passos necessários para que o projeto execute corretamente, de forma automatizada, siga os seguintes passos:
 
1. [TerraForm](#Terraform)
    - Serviços
2. [Kubernetes](#Kubernetes)
    - Ingress Nginx
3. [Consideracoes Finais](#LastComment)

Caso deseje fazer o processo manualmente de criação de cada parte dos recursos, provisionamento da aplicação e entender de forma detalhada de como funciona cada parte do processo, siga os pasos abaixo:

1. [TerraForm](#Terraform)
    - Infra-Estrutura
2. [AWS](#AWS)
    - CodePipeline
    - CodeBuild
    - EKS
3. [Kubernetes](#Kubernetes)
    - Ingress Nginx
    - Storage Class
    - MongoDB
    - Aplicação
4. [Aplicação](#Application)
5. [TerraForm](#Terraform)
    - Serviços
6. [Consideracoes Finais](#LastComment)
 
#Terraform
---
## TerraForm
---
 
Neste projeto optamos pela utilização do TerraForm (IaC), pela praticidade e facilidade que temos com ele. Por ter sido projeto para se utilizar com equipes grandes de desenvolvimento, trabalhando todos os processos necessários para este tipo de ação, ele conta com sistema de Lock, quando necessário, com armazenamento de suas configurações em nuvem, tendo toda a gestão para evitar falhas gerenciadas por ele.
 
Este projeto do TerraForm foi organizado na seguinte maneira:
 
```
Terraform/
    |- Global/ -> Responsável por armazenar todos os recursos que são globais do projeto.
    |    |- main.tf -> Criação de Bucket e DynamoDB
    |- Infraestructure/ -> Responsável por armazenar toda a infraestrutura necessária para a aplicação executar.
    |    |- Development/ -> Infraestrutura do ambiente de Desenvolvimento.
    |    |    |- vpc/ -> Responsável por criar a VPC necessária para os recursos deste ambiente.
    |    |- Production/ -> Infraestrutura do ambiente de Production.
    |- Modules/ -> Responsável por armazenar todos os arquivos de Módulos, que são reaproveitados quando necessários.
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
 
Todo esse primeiro processo do Backend "S3" e o DynamoDB, está codificado em um TF File deste repositório, que está na pasta *TerraForm/Global*. Para executarmos esse TF File, e provisionar a infraestrutura inicial para o TerraForm e todo o conjunto codificado neste projeto, será necessário configurarmos três variáveis de ambiente neste projeto, sendo elas descritas abaixo:
 
```
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
export AWS_DEFAULT_REGION=""
```
 
Estas variáveis de ambiente são responsável por conceder o acesso a AWS e permitir ao TerraForm criar e gerenciar os recursos na nuvem. Para obter essas credenciais é necessário seguir o seguinte tutorial: [AWS IAM](https://docs.aws.amazon.com/pt_br/general/latest/gr/managing-aws-access-keys.html).
 
Por padrão este projeto está configurado para criar um bucket com o nome __*terraform-state-files-hotmart*__, caso deseje mudar o nome do Bucket ou caso de erro na criação por duplicidade no nome do Bucket, recomendo que edite os arquivos __*main.tf*__, das pastas *Infraestructure/(Development/Production)* e *Services/(Development/Production)*, na tag __*Terraform{ backend "s3" {}}*__ para o novo nome de Bucket desejado.
 
Após a configuração necessária para o TerraForm acessar a AWS, será necessária a execução de dois comandos TerraForm, sendo eles:
 
```
terraform init  -> Responsável por baixar e preparar todas as dependências do TerraForm.
terraform apply -auto-approve -> Responsável por criar e gerenciar toda a infraestrutura descrita em cada arquivo TF.
```
> Estes comandos devem ser executados dentro da pasta principal de cada Serviço/InfraEstrutura. No caso acima, será necessário executar este comando na pasta *Terraform/Global*
 
Ao finalizar a execução de ambos os comandos, será criado um Bucket S3 para armazenar todos os arquivos Tf State, uma tabela no Dynamo DB para fazer a gestão de cada Locks e uma chave KMS, para criptografar os arquivos quando necessários.
 
### Serviços
 
Nesta etapa já estamos prontos para criarmos os serviços necessários para a automação de build e provisão de recursos deste projeto. Dentro da pasta *Services/Development* ou *Services/Production*, existe um arquivo *main.tf* que é responsável por agrupar todos os recursos necessários, junto com os recursos existem alguns valores que podem ser modificados, para criar ambientes diferentes sempre que necessário, esses valores estão descritos dentro da tag __*locals { }*__, pela qual armazena todas as configurações locais deste Tf File, desta forma caso queira mudar algo para sua infraestrutura gerada, recomendo que modifique neste arquivo.
 
Para que ocorra tudo perfeitamente com a criação do CodeBuild e seu processo de automação, é necessário que seja feita duas configurações nos arquivos TF File. A primeira será necessário modificar a tag __*locals { }*__, que consiste em modificar a chave: __*OAuthToken*__. Essa chave é responsável por permitir o acesso ao repositório e ao WebHook, entre o GitHub e o AWS CodePipeline, sem a criação deste Token, não será possível o AWS CodePipeline acessar os arquivos no repositório. Para criar o __*OAuthToken*__ no GitHub, segue o tutorial: [GitHub](https://docs.cachethq.io/docs/github-oauth-token). A segunda modificação, consiste em modificar o arquivo *main.tf*, existente na pasta __*Terraforms/Services/(Development/Production)*__, na __*linha 48*__, colocando o valor da chave KMS criada anteriomente.

Para iniciar o processo de criação dos serviços é necessário executar os seguintes comandos:
 
```
terraform init  -> Responsável por baixar e preparar todas as dependências do TerraForm.
terraform apply -auto-approve -> Responsável por criar e gerenciar toda a infraestrutura descrita em cada arquivo TF.
```
> Estes comandos devem ser executados dentro da pasta principal de cada Serviço/InfraEstrutura. No caso acima, será necessário executar este comando na pasta *Terraform/Serviços/__(Development/Production)__*, de acordo com qual ambiente deseja provisionar.

Após a finalização da criação dos recursos de serviço, será armazenado um arquivo TF State no Backend "S3" e o build irá iniciar automaticamente pelo CodePipeline, com este Build Iniciado, não será necessário mais nenhuma etapa de criação de recurso, todos os recursos necessários serão providos pelo CodePipeline e sua Build automatizada, sendo necessário apenas modificar o arquivo Kubernetes do Ingress Nginx, para setar o certificado HTTPs correto para nossa aplicação. No tópico do Ingress, temos a maneira certa de se fazer essa correção.
 
### Infra-Estrutura
 
Iremos criar a arquitetura necessária para que nossa aplicação seja provisionada. Nesta etapa optamos por utilizar o EKS, pela questão da segurança, praticidade e compatibilidade com os recursos da AWS, além de nos prover uma rápida escalabilidade e uma alta disponibilidade.
 
Para isso optamos por criar uma VPC exclusiva para o EKS e seus workers, sendo divididas em 4 Subnets, sendo 2 delas para operar junto com o EKS Cluster Principal e 2 outras para operarmos com seus Node Group. Optamos por utilizar uma VPC com acesso a internet, para facilitar o gerenciamento do Cluster, entretanto é altamente recomendado que seja configurado um Cluster, que tenha 2 subnets privadas e 2 subnets públicas, para que sejam utilizados de acordo com a necessidade do serviço, podendo ser um serviço que não necessite acesso externo ou um serviço que necessite de um acesso externo.
 
Criado o EKS, é necessário que seja criado o Node Group(Workes), para que tenhamos os recursos necessário para prover nossa aplicação. Cada Node Group é necessário que sejam selecionados as Instâncias EC2 desejada, as subnets que serão utilizadas pelas instâncias, e o tamanho desejado de workers, sendo configurado por *desejado*, *máximo*, *mínimo*. Feitas todas essas configurações seu Node Group estará pronto para ser utilizado, e seu EKS também estará pronto para prover aplicações.
 
Neste projeto temos os arquivos TF Files necessários para criarmos automaticamente todo o EKS, sendo desde a parte do VPC, Node Group e Route53. Dentro da pasta *Infraestructure/(Development/Production)*, existe um arquivo *main.tf* que é responsável por agrupar todos os recursos necessários, junto com os recursos existem alguns valores que podem ser modificados, para criar ambientes diferentes sempre que necessário, esses valores estão descritos dentro da tag __*locals { }*__, pela qual armazena todas as configurações locais deste Tf File, desta forma caso queira mudar algo para sua infraestrutura gerada, recomendo que modifique neste arquivo. Caso deseje modificar o VPC gerado, é necessário modificar apenas o *main.tf* que está dentro da pasta *Infraestructure/(Development/Production)/vpc*.
 
Optamos por criar automaticamente o Route53, sendo ele gerado a partir dos valores configurados para a criação do EKS. O DNS criado teria o nome: *{environment}.{cluster_name}.{user_identity}.{aws_region}.com*, gerando também os certificados WildCard pelo Certificate Manager, ficando **.{environment}.{cluster_name}.{user_identity}.{aws_region}.com*. Este DNS criado, será utilizado para o acesso a aplicação.

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
 
### CodePipeline
 
Optamos por utilizar o CodePipeline pela praticidade de integração com todos os recursos da AWS, e fácil integração com o source de nosso projeto, que está hospedado no GitHub. Para utilizarmos ele, usamos o WebHook do GitHub para disparar os Build de forma automatizada, sempre que ocorrer algum push no projeto. Junto com ele utilizamos o CodeBuild, para prover todo o Build automático de nosso projeto.
 
O CodePipeline é responsável por gerenciar todo o pipeline de nosso projeto e dessa forma unir todos os outros recursos de desenvolvimento da AWS em uma única plataforma, facilitando todo o processo de gerência e análise. Podemos utilizar o CodeCommit, GitHub, S3, etc, como repositórios de códigos, e ao subir algum arquivo o CodePipeline iniciaria o processo de build. Dessa forma é uma ferramenta poderosa, quando se usado nos ambientes da AWS.
 
Para o processo de build, optamos por utilizar o CodeBuild, pela praticidade na integração com o CodePipeline e os recursos da AWS. É necessário apenas escrever um arquivo *buildspec.yml* no projeto e definir todos os passos necessários para o processo de build da aplicação.
> Este arquivo *buildspec.yml* está definido no root deste repositório, por questões de praticidade. Nas considerações finais, terá uma overview de toda organização deste repositório.
 
 
#### CodeBuild
 
Para configuração do CodeBuild, optamos por configurar uma máquina mais lenta para o ambiente de *development* e uma máquina mais poderosa para o ambiente de *production*, por questões de custo. É possível configurar uma rede VPC, para que o CodeBuild tenha acesso a rede interna da AWS, porém optamos por não configurar, pela não necessidade de acesso a alguma aplicação interna.
 
 
### EKS
 
Optamos pela utilização do EKS para este projeto, graças a sua escalabilidade, alta disponibilidade, divisão de responsabilidade e __segurança__.
 
#Kubernetes
---
## Kubernetes
---
 
O Kubernetes é uma poderosa ferramenta de orquestração de containers, com ela podemos organizar os recursos da melhor maneira e ainda criar *réplicas* de nossas aplicações, para caso ocorra algum desastre a aplicação não fique fora do ar. Além disso, é uma das ferramentas com maior contribuição do GitHub, sendo uma comunidade forte e ativa de desenvolvimento. É possível também desenvolver plugins e serviços, que rodam junto ao Kubernetes e assim automatizar ainda mais todo o ambiente, e um desses exemplos seria o Ingress (Nginx ou ALB), cert-manager(Geração de Certificado Válidos), replicator(Réplica secrets), etc. Ao se utilizar todos os recursos que o Kubernetes nos provê, é possível ter uma infraestrutura robusta e com todos os recursos necessários para se executar uma aplicação perfeitamente.
 
Neste projeto, optamos por deixar o EKS fazer toda a gestão de recursos na nuvem necessárias para que a aplicação execute com segurança e escalabilidade. Dessa forma, optamos por utilizar um Ingress Nginx, no lugar de um ALB, pela questão de praticidade de se aplicar esse recurso e principalmente pela questão de custo que teríamos ao utilizar. Um ALB tem um custo fixo mensal de $25 e ainda existe um custo variável que ocorre de acordo com a quantidade de dados trafegados e a quantidade de requisições por mês, dessa forma poderia deixar um projeto pequeno inviável. O Ingress Nginx utiliza os recursos das próprias máquinas do Kubernetes, e por necessitar de um processamento baixo e de pouca memória, faz com que o custo com essa aplicação seja pequena, e ela funcione perfeitamente nestes casos de uso. Uma vantagem do ALB, seria a utilização de TCP (Secure), o que o Ingress Nginx não atenderia as especificações, portanto sempre recomendo analisar muito bem quais as necessidades dos serviços que serão providos pelo ingress.
 
Os arquivos Kubernetes deste projeto estão armazenados na pasta *Kubernetes/*, eles estão divididos em dois conjuntos *Kubernetes/Application* e *Kubernetes/Services*. Segue uma explicação detalhada de cada pasta:
 
```
Kubernetes/
    |- Application/ -> Responsável por armazenar todos os arquivos yaml das aplicações deste projeto.
    |    |- Development/ -> Arquivos yaml do ambiente de Development.
    |    |- Production/ -> Arquivos yaml do ambiente de Production.
    |- Services/ -> Responsável por armazenar toda a infraestrutura de serviços necessários para a aplicação executar.
    |    |- Ingress-Nginx/ -> Arquivos yaml do Ingress Nginx.
    |    |- MongoDB/ -> Arquivos yaml do MongoDB.
```
 
Responsabilidade de cada arquivo Yaml da aplicação:
 
```
Kubernetes/
    |- namespace.yaml -> Responsável pela criacao do namespace.
    |- configmap.yaml -> Responsável pela criacao do configmap.
    |- secrets.yaml -> Responsável por armazenar as secrets do projeto.
    |- services.yaml -> Responsável pela criacao do services da aplicação(NodePort, ClusterIP ou LoadBalancer).
    |- deployment.yaml -> Responsável pela criação do deployment da aplicação.
    |- ingress.yaml -> Responsável pela geração do Ingress da aplicação.
```
> Obs1: Os arquivos contêm uma sequência de números iniciais como por exemplo *00-*, para que sejam aplicados na ordem certa, e haja uma organização. Como um arquivo yaml, pode depender do recurso existente no outro, e altamente recomendado que seja organizado desta forma.
 
> Obs2: Optamos por criar o arquivo de *secrets.yaml*. É altamente recomendado que seja utilizado um serviço de secrets dinâmico, como secret manager, vault, etc, para que as secrets fiquem armazenadas em um local seguro e com acesso restrito, podendo gerar problemas caso esteja no repositório. 
 
A todo momento em que for feito uma Build nova da aplicação estaremos aplicando esses arquivos do Kubernetes, para atualizarmos as configurações de cada recurso do EKS.
 
Para provisionar essa aplicacao de maneira manual, sem o CodeBuild aplicar os arquivos yaml, é necessário executar apenas um comando. Segue o comando abaixo:
 
```
kubectl apply -f . -> Irá aplicar todos os arquivos Yaml de seu diretório atual.
```
> É necessário estar dentro da pasta que deseja aplicar os arquivos ou trocar o __*.*__ pela pasta de destino dos arquivos Yaml, que deseja aplicar.
 
### Ingress Nginx
 
Para utilizarmos o Ingress Nginx criamos um LoadBalancer de Layer 3(ELB), o objetivo deste LoadBalancer será para que as requisições possam chegar aos servidores web corretamente. Para criarmos os recursos necessários para o Kubernetes reconhecer o Ingress Nginx e ele funcionar como um Application Gateway, e necessário aplicar seus arquivos yaml, estes arquivos estão dentro da pasta *Kubernetes/Services/Ingress-Nginx*. Comando necessário para aplicar:
 
```
kubectl apply -f . -> Irá aplicar todos os arquivos Yaml de seu diretório atual.
```
> É necessário estar dentro da pasta *Kubernetes/Services/Ingress-Nginx* ou trocar o __*.*__ por __*Kubernetes/Services/Ingress-Nginx*__.
 
Após aplicarmos corretamente os arquivos de configuração do Ingress Nginx e o LoadBalancer estiver criado corretamente, teremos um acesso às aplicações que estiverem hospedadas no Kubernetes, sendo necessário apenas configurar no DNS para apontar para o DNS do LoadBalancer criado. Caso não saiba apontar no Route 53, veja este [tutorial](https://docs.aws.amazon.com/pt_br/Route53/latest/DeveloperGuide/routing-to-elb-load-balancer.html). Após fazer essa apontamento no Route53 é necessário fazer a correção nos arquivos *ingress.yaml*, que estão em *Kubernetes/Application/(Development/Production)*, para o Zone criada pelo TerraForm, criando assim o Sub Dominio desejado para acessar a aplicação, já existe um exemplo no arquivo, será necessário apenas substituir pelo desejado.
 
Essa parte de apontamento do DNS do LoadBalancer no Route53, deverá ser feita manualmente, pois essa parte ainda não está automatizada neste processo. Uma forma de automatizar esse processo seria criando um serviço que rodaria junto ao Ingress e ele automaticamente registraria no Route53 a todo momento que for criado um novo Ingress no Kubernetes, dessa forma seria necessário apenas a criação do Ingress, sem a necessidade de criar no Route53, em *Python* uma aplicação deste porte seria feita rapidamente, recomendo que leia sobre a documentacao do [Boto3](https://github.com/boto/boto3) e [Kubernetes-Client Python](https://github.com/kubernetes-client/python), em outro momento irei criar um repositório com a aplicação que gerencia essa parte.
 
Com este poderoso LoadBalancer, poderemos configurar duas aplicações respondendo para a mesma URL, porém apontando para locais diferentes, como por exemplo: *https://application.onredes.com* (FrontEnd) - *https://application.onredes.com/api/* (BackEnd). Utilizando essa ferramenta podemos diminuir os custos de nossas aplicações.
 
Caso optassem por utilizar o ALB, poderíamos gerar ele automaticamente pelo Terraform, cadastrar o Route53 pelo TerraForm e ainda validar os certificados, porém como optamos em utilizar o Nginx focando em custo, não será possível fazer isso.

Para configurar o certificado criado pelo Certificate Manager no LoadBalancer do Ingress é necessário editar o arquivo *02-services.yaml*, que está dentro da pasta *Kubernetes/Ingress-Nginx*, descomentando a __linha 11__ e substituindo o arn existente, pelo gerado do Certificar Manager, gerado pelo TerraForm, após isso todas as requisições provenientes a porta 443 do LoadBalancer irão conter certificados HTTPs.

> __Caso deseje utilizar um ALB no lugar de um Ingress Nginx, estará disponível na branch *release/terraform*. Lá você terá um exemplo completo utilizando o TerraForm, LoadBalancer, sem a necessidade do Nginx Ingress.__

### Storage Class
 
Ao se trabalhar com o Kubernetes em um provider, e principalmente ao termos o EKS, podemos configurar facilmente a criação de storages quando necessário, para isso é necessário criar classes de Storage, existem algumas que são criadas por padrão, como por exemplo *local*, porém algumas são necessárias criar manualmente, pela quantidade de opções que podemos ter.
 
Neste caso optamos por criar duas classes essencialmente, são elas *slow* e *fast*, essas classes definem qual o tipo de armazenamento que será utilizado para armazenar os arquivos das aplicações. Uma forma muito utilizada para isso é para os bancos de dados, como por exemplo *MongoDB* que necessita de um banco de dados de IOPs alto, e ao selecionarmos o Storage Class correto, temos ganho em performance e tudo ocorre de forma automatizada.
 
Para aplicarmos os arquivos de configuração do Storage Class, é necessário executar os seguintes comandos:
 
```
kubectl apply -f . -> Irá aplicar todos os arquivos Yaml de seu diretório atual.
```
> É necessário estar dentro da pasta *Kubernetes/Services/Storage-Class* ou trocar o __*.*__ por __*Kubernetes/Services/Storage-Class*__.
 
### MongoDB
 
Nossa aplicação necessita de um banco de dados MongoDB para que se provisione corretamente a aplicação. Para isso utilizaremos o tipo StatefulSet, pela questão de ser um banco de dados de alta disponibilidade e de fácil configuração, unido ao poder do StatefulSet, temos um banco completamente configurado, alta disponibilidade e fácil escalabilidade. Para conhecer mais sobre os [StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/).
 
Para aplicar e criar o banco de dados MongoDB, é necessário executar os seguintes comandos: 
 
```
kubectl apply -f . -> Irá aplicar todos os arquivos Yaml de seu diretório atual.
```
> É necessário estar dentro da pasta *Kubernetes/Services/MongoDB* ou trocar o __*.*__ por __*Kubernetes/Services/MongoDB*__.
 
### Aplicação
 
Para criarmos os recursos da aplicação no Kubernetes é necessário aplicarmos os arquivos YAML que estão dentro do folder *Application/(Development/Production)*, estes arquivos irão criar os configmaps, secrets, namespaces, serviços, deployments e ingress. Para isso execute o comando abaixo:
 
```
kubectl apply -f .
```
> É necessário estar dentro da pasta *Kubernetes/Services/MongoDB* ou trocar o __*.*__ por __*Kubernetes/Application//(Development/Production)*__.
 
Um importante ponto a ser analisado está nas configurações de imagens do kubernetes, o arquivo YAML de Deployment está configurado para a imagem __*.*__ (pelo qual nao existe), porem ao passar pelo CodeBuild será feito a correção e o deployment seria corrigido com a imagem correta, gerada pelo CodeBuild. Caso deseje pode modificar o arquivo YAML de Deployment para o repositório de imagem correto, o repositório foi gerado automaticamente junto ao CodeBuild e se encontra no ECR, lembre-se de colocar o repositório correto em cada aplicação.
 
#Application
---
## Aplicação
---
 
Este projeto não tem como foco a aplicação feita, apenas demonstrar o processo de provisionamento de uma InfraEstrutura, utilizando a AWS, EKS e o TerraForm, sera dada apenas uma explicação rapida e simples deste projeto. Este projeto foi selecionado pelo fato de ser uma aplicação que contém FrontEnd, BackEnd e um Banco de Dados, que simula muito bem uma aplicação simples. Ele contém um FrontEnd estático, provisionado por uma imagem Docker proveniente de uma imagem do [Nginx](https://hub.docker.com/_/nginx), e um BackEnd, provisionado por uma imagem Docker proveniente de uma imagem do [NodeJS](https://hub.docker.com/_/node), fazendo o processo de Build e automatização de maneira prática e fácil.
 
Para o build do FrontEnd, optamos por utilizar uma imagem Docker com o NodeJS e o Nginx, fazendo um multi-build stage, porém existem outras formas mais práticas para fazermos esse processo, uma delas seria o CodeBuild buildar o código em React e o Docker utilizar apenas o código Buildado, neste processo ganhamos o poder de facilitar o Build, pois ao utilizarmos o Build por Environment Variable podemos ter problemas ao setar essas variáveis dentro do Build do Docker, podendo se tornar um processo oneroso, o que quando colocamos buildando no CodeBuild diretamente e não no docker, não corre.
 
Para que esta aplicação funcione corretamente, é necessário que se tenha as seguintes variáveis de ambiente:
 
```
SECRET_OR_KEY - Reponsavel pela Secret Key utilizada pelo JWT. (Secret)
SERVER_TYPE - Selecionar o formato que ia ser executado a aplicação. (Configmap)
MONGO_URI - URI do Banco de dados do MongoDB (mongodb://). (Secret)
URL_BASE - URL Base da aplicação. (Configmap)
NODE_ENV - Environment da aplicacao. (Configmap)
PORT - Porta pelo qual irá rodar. (Configmap)
```

Essa aplicação foi retirada de um curso do Missão DevOps. Dou todos os créditos de desenvolvimento para o site [Missão DevOps](http://missaodevops.com.br/).
 
#LastComment
---
## Considerações Finais
---
 
Todo este projeto está automatizado para ser utilizado como Infraestructure-as-Code, sendo necessário apenas o apply inicial, para que seja provisionado toda a automação desejada. Este apply inicial pode ser feito a partir do build do Dockerfile existente dentro da pasta *Terraform/*, dessa forma facilita a configuração inicial da aplicação.
 
O BuildSpec deste projeto foi feito pensando que todos os arquivos estavam no mesmo repositório, porém foi desenhado já pensando no caso de termos de criar repositorios fixos para o Terraform, Kubernetes e a Application, como o contexto pode mudar e aplicações tendem a aumentar de tamanho, temos sempre de imaginar em como escalar determinado projeto, e dessa forma fica fácil escalar todo o necessário.

O AWS EKS existe algumas limitações, por questão de segurança, para ser feito o primeiro acesso ao Cluster é necessário estar com as permissões do usuário que gerou o Cluster, pois assim a AWS consegue controlar o acesso ao Cluster. Após feito esse primeiro acesso com este usuário é possível adicionar novos acessos seguindo o seguinte tutorial: [AWS EKS IAM](https://docs.aws.amazon.com/pt_br/eks/latest/userguide/managing-auth.html).

Optamos por utilizar um IAM de Administrador, pela praticidade que isso pode nos prover, mas é altamente recomendado utilizarmos somente as permissões necessárias para a criação da infraestrutura.. Abaixo irei descrever as IAM necessárias para a ciação de cada processo.

### EKS

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "eks:ListNodegroups",
                "eks:UntagResource",
                "eks:ListTagsForResource",
                "eks:UpdateClusterConfig",
                "eks:CreateNodegroup",
                "eks:DeleteCluster",
                "eks:UpdateNodegroupVersion",
                "eks:DescribeNodegroup",
                "eks:ListUpdates",
                "eks:DeleteNodegroup",
                "eks:DescribeUpdate",
                "eks:TagResource",
                "eks:UpdateNodegroupConfig",
                "eks:DescribeCluster"
            ],
            "Resource": [
                "arn:aws:eks:*:*:cluster/*",
                "arn:aws:eks:*:*:nodegroup/*/*/*"
            ]
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "eks:ListClusters",
                "eks:CreateCluster"
            ],
            "Resource": "*"
        }
    ]
}
```

### Route53

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "route53:ListTagsForResources",
                "route53:GetHostedZone",
                "route53:ChangeResourceRecordSets",
                "route53:ChangeTagsForResource",
                "route53:DeleteHostedZone",
                "route53:UpdateHostedZoneComment",
                "route53:CreateVPCAssociationAuthorization",
                "route53:ListTagsForResource"
            ],
            "Resource": "arn:aws:route53:::hostedzone/*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "route53:CreateHostedZone",
                "route53:CreateReusableDelegationSet",
                "route53:ListHostedZones",
                "route53:ListHostedZonesByName"
            ],
            "Resource": "*"
        }
    ]
}
```

### Certificate Manager
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "acm:DeleteCertificate",
                "acm:DescribeCertificate",
                "acm:GetCertificate",
                "acm:RemoveTagsFromCertificate",
                "acm:UpdateCertificateOptions",
                "acm:AddTagsToCertificate",
                "acm:RenewCertificate"
            ],
            "Resource": "arn:aws:acm:*:*:certificate/*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "acm:RequestCertificate",
                "acm:ListCertificates",
                "acm:ListTagsForCertificate"
            ],
            "Resource": "*"
        }
    ]
}
```

### CodePipeline
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "codepipeline:PutApprovalResult",
                "codepipeline:PutActionRevision"
            ],
            "Resource": "arn:aws:codepipeline:*:*:*/*/*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "codepipeline:EnableStageTransition",
                "codepipeline:RetryStageExecution",
                "codepipeline:DisableStageTransition"
            ],
            "Resource": "arn:aws:codepipeline:*:*:*/*"
        },
        {
            "Sid": "VisualEditor2",
            "Effect": "Allow",
            "Action": [
                "codepipeline:RegisterWebhookWithThirdParty",
                "codepipeline:PollForJobs",
                "codepipeline:TagResource",
                "codepipeline:DeleteWebhook",
                "codepipeline:DeregisterWebhookWithThirdParty",
                "codepipeline:ListWebhooks",
                "codepipeline:UntagResource",
                "codepipeline:CreateCustomActionType",
                "codepipeline:ListTagsForResource",
                "codepipeline:DeleteCustomActionType",
                "codepipeline:PutWebhook",
                "codepipeline:ListActionTypes"
            ],
            "Resource": [
                "arn:aws:codepipeline:*:*:webhook:*",
                "arn:aws:codepipeline:*:*:actiontype:*/*/*/*"
            ]
        },
        {
            "Sid": "VisualEditor3",
            "Effect": "Allow",
            "Action": [
                "codepipeline:PutThirdPartyJobFailureResult",
                "codepipeline:PutThirdPartyJobSuccessResult",
                "codepipeline:PollForThirdPartyJobs",
                "codepipeline:PutJobFailureResult",
                "codepipeline:PutJobSuccessResult",
                "codepipeline:AcknowledgeJob",
                "codepipeline:AcknowledgeThirdPartyJob",
                "codepipeline:GetThirdPartyJobDetails",
                "codepipeline:GetJobDetails"
            ],
            "Resource": "*"
        }
    ]
}
```

### CodeBuild
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "codebuild:BatchGetProjects",
                "codebuild:DeleteWebhook",
                "codebuild:ListReportsForReportGroup",
                "codebuild:InvalidateProjectCache",
                "codebuild:DescribeTestCases",
                "codebuild:BatchGetReports",
                "codebuild:StopBuild",
                "codebuild:DeleteReportGroup",
                "codebuild:UpdateWebhook",
                "codebuild:ListBuildsForProject",
                "codebuild:CreateWebhook",
                "codebuild:CreateProject",
                "codebuild:BatchGetBuilds",
                "codebuild:UpdateReportGroup",
                "codebuild:CreateReportGroup",
                "codebuild:CreateReport",
                "codebuild:UpdateReport",
                "codebuild:DeleteReport",
                "codebuild:BatchDeleteBuilds",
                "codebuild:DeleteProject",
                "codebuild:StartBuild",
                "codebuild:BatchGetReportGroups",
                "codebuild:BatchPutTestCases"
            ],
            "Resource": [
                "arn:aws:codebuild:*:*:report-group/*",
                "arn:aws:codebuild:*:*:project/*"
            ]
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "codebuild:ImportSourceCredentials",
                "codebuild:ListReports",
                "codebuild:ListBuilds",
                "codebuild:ListCuratedEnvironmentImages",
                "codebuild:DeleteOAuthToken",
                "codebuild:ListReportGroups",
                "codebuild:ListSourceCredentials",
                "codebuild:ListProjects",
                "codebuild:DeleteSourceCredentials",
                "codebuild:ListRepositories",
                "codebuild:PersistOAuthToken",
                "codebuild:ListConnectedOAuthAccounts"
            ],
            "Resource": "*"
        }
    ]
}
```

### ECR
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ecr:PutImageTagMutability",
                "ecr:DescribeImageScanFindings",
                "ecr:StartImageScan",
                "ecr:GetLifecyclePolicyPreview",
                "ecr:CreateRepository",
                "ecr:PutImageScanningConfiguration",
                "ecr:ListTagsForResource",
                "ecr:ListImages",
                "ecr:DeleteLifecyclePolicy",
                "ecr:DeleteRepository",
                "ecr:UntagResource",
                "ecr:SetRepositoryPolicy",
                "ecr:BatchGetImage",
                "ecr:DescribeImages",
                "ecr:TagResource",
                "ecr:DescribeRepositories",
                "ecr:StartLifecyclePolicyPreview",
                "ecr:DeleteRepositoryPolicy",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetRepositoryPolicy",
                "ecr:GetLifecyclePolicy"
            ],
            "Resource": "arn:aws:ecr:*:*:repository/*"
        }
    ]
}
```

### EC2
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:DeleteTags",
                "ec2:DeleteVpcPeeringConnection",
                "ec2:AcceptVpcPeeringConnection",
                "ec2:CreateTags",
                "ec2:DeleteRoute",
                "ec2:RevokeClientVpnIngress",
                "ec2:ReplaceRoute",
                "ec2:RejectVpcPeeringConnection",
                "ec2:DeleteRouteTable",
                "ec2:RevokeSecurityGroupIngress",
                "ec2:CreateRoute",
                "ec2:RevokeSecurityGroupEgress",
                "ec2:DeleteSecurityGroup",
                "ec2:DisableVpcClassicLink",
                "ec2:CreateVpcPeeringConnection",
                "ec2:EnableVpcClassicLink"
            ],
            "Resource": [
                "arn:aws:ec2:*:*:vpc-peering-connection/*",
                "arn:aws:ec2:*:*:route-table/*",
                "arn:aws:ec2:*:*:client-vpn-endpoint/*",
                "arn:aws:ec2:*:*:security-group/*",
                "arn:aws:ec2:*:*:vpc/*"
            ]
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "ec2:DeleteSubnet",
                "ec2:DescribeInstances",
                "ec2:ModifyVpcEndpointServiceConfiguration",
                "ec2:ReplaceRouteTableAssociation",
                "ec2:DeleteVpcEndpoints",
                "ec2:AttachInternetGateway",
                "ec2:DescribeByoipCidrs",
                "ec2:AssociateVpcCidrBlock",
                "ec2:AssociateRouteTable",
                "ec2:DisassociateVpcCidrBlock",
                "ec2:DescribeInternetGateways",
                "ec2:CreateInternetGateway",
                "ec2:ModifyVpcPeeringConnectionOptions",
                "ec2:DescribeNetworkInterfacePermissions",
                "ec2:DescribeNetworkAcls",
                "ec2:DescribeRouteTables",
                "ec2:RejectVpcEndpointConnections",
                "ec2:DescribeEgressOnlyInternetGateways",
                "ec2:CreateVpcEndpointConnectionNotification",
                "ec2:DescribeVpcClassicLinkDnsSupport",
                "ec2:DescribeVpcPeeringConnections",
                "ec2:ModifyNetworkInterfaceAttribute",
                "ec2:ResetNetworkInterfaceAttribute",
                "ec2:CreateRouteTable",
                "ec2:DeleteNetworkInterface",
                "ec2:DescribeVpcEndpointServiceConfigurations",
                "ec2:DetachInternetGateway",
                "ec2:DisassociateRouteTable",
                "ec2:ModifyVpcEndpointConnectionNotification",
                "ec2:DescribeVpcClassicLink",
                "ec2:CreateNetworkInterface",
                "ec2:CreateVpcEndpointServiceConfiguration",
                "ec2:DescribeVpcEndpointServicePermissions",
                "ec2:CreateDefaultVpc",
                "ec2:AssociateSubnetCidrBlock",
                "ec2:DeleteNatGateway",
                "ec2:CreateEgressOnlyInternetGateway",
                "ec2:DeleteVpc",
                "ec2:DescribeVpcEndpoints",
                "ec2:CreateSubnet",
                "ec2:DescribeSubnets",
                "ec2:DescribeVpnGateways",
                "ec2:ModifyVpcEndpoint",
                "ec2:DeprovisionByoipCidr",
                "ec2:ModifyVpcEndpointServicePermissions",
                "ec2:DescribeAddresses",
                "ec2:CreateNatGateway",
                "ec2:DescribeInstanceAttribute",
                "ec2:DescribeRegions",
                "ec2:CreateVpc",
                "ec2:DescribeDhcpOptions",
                "ec2:DescribeVpcEndpointServices",
                "ec2:DeleteVpcEndpointServiceConfigurations",
                "ec2:DescribeVpcAttribute",
                "ec2:CreateDefaultSubnet",
                "ec2:DeleteNetworkInterfacePermission",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeAvailabilityZones",
                "ec2:CreateSecurityGroup",
                "ec2:DescribeNetworkInterfaceAttribute",
                "ec2:CreateNetworkAcl",
                "ec2:ModifyVpcAttribute",
                "ec2:DescribeVpcEndpointConnections",
                "ec2:DescribeInstanceStatus",
                "ec2:DeleteEgressOnlyInternetGateway",
                "ec2:DetachNetworkInterface",
                "ec2:AcceptVpcEndpointConnections",
                "ec2:DescribeTags",
                "ec2:DescribeNatGateways",
                "ec2:DisassociateSubnetCidrBlock",
                "ec2:DescribeVpcEndpointConnectionNotifications",
                "ec2:DescribeSecurityGroups",
                "ec2:DeleteVpcEndpointConnectionNotifications",
                "ec2:DescribeSecurityGroupReferences",
                "ec2:CreateVpcEndpoint",
                "ec2:DescribeVpcs",
                "ec2:DisableVpcClassicLinkDnsSupport",
                "ec2:AttachNetworkInterface",
                "ec2:EnableVpcClassicLinkDnsSupport",
                "ec2:ModifyVpcTenancy",
                "ec2:CreateNetworkAclEntry"
            ],
            "Resource": "*"
        }
    ]
}
```

### CloudWatch
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "logs:ListTagsLogGroup",
                "logs:DisassociateKmsKey",
                "logs:DescribeLogGroups",
                "logs:UntagLogGroup",
                "logs:DeleteLogGroup",
                "logs:DescribeLogStreams",
                "logs:PutMetricFilter",
                "logs:CreateLogStream",
                "logs:TagLogGroup",
                "logs:DeleteRetentionPolicy",
                "logs:AssociateKmsKey",
                "logs:PutSubscriptionFilter",
                "logs:PutRetentionPolicy",
                "logs:GetLogGroupFields"
            ],
            "Resource": "arn:aws:logs:*:*:log-group:*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "logs:GetLogEvents",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:log-group:*:log-stream:*"
        },
        {
            "Sid": "VisualEditor2",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogDelivery",
                "logs:DeleteResourcePolicy",
                "logs:GetLogRecord",
                "logs:PutResourcePolicy",
                "logs:PutDestinationPolicy",
                "logs:UpdateLogDelivery",
                "logs:DeleteLogDelivery",
                "logs:DeleteDestination",
                "logs:CreateLogGroup",
                "logs:GetLogDelivery",
                "logs:PutDestination",
                "logs:ListLogDeliveries"
            ],
            "Resource": "*"
        }
    ]
}
```

### IAM
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "iam:UpdateAssumeRolePolicy",
                "iam:GetPolicyVersion",
                "iam:DeleteAccessKey",
                "iam:ListRoleTags",
                "iam:DeleteGroup",
                "iam:RemoveRoleFromInstanceProfile",
                "iam:UpdateGroup",
                "iam:CreateRole",
                "iam:AttachRolePolicy",
                "iam:PutRolePolicy",
                "iam:CreateLoginProfile",
                "iam:DetachRolePolicy",
                "iam:SimulatePrincipalPolicy",
                "iam:ListAttachedRolePolicies",
                "iam:DetachGroupPolicy",
                "iam:ListRolePolicies",
                "iam:DetachUserPolicy",
                "iam:PutGroupPolicy",
                "iam:UpdateLoginProfile",
                "iam:UpdateServiceSpecificCredential",
                "iam:GetRole",
                "iam:CreateGroup",
                "iam:GetPolicy",
                "iam:UpdateUser",
                "iam:GetAccessKeyLastUsed",
                "iam:ListEntitiesForPolicy",
                "iam:DeleteUserPolicy",
                "iam:AttachUserPolicy",
                "iam:DeleteRole",
                "iam:UpdateRoleDescription",
                "iam:UpdateAccessKey",
                "iam:GetUserPolicy",
                "iam:ListGroupsForUser",
                "iam:DeleteServiceLinkedRole",
                "iam:GetGroupPolicy",
                "iam:GetRolePolicy",
                "iam:CreateInstanceProfile",
                "iam:UntagRole",
                "iam:PutRolePermissionsBoundary",
                "iam:TagRole",
                "iam:DeletePolicy",
                "iam:DeleteRolePermissionsBoundary",
                "iam:CreateUser",
                "iam:GetGroup",
                "iam:CreateAccessKey",
                "iam:ListInstanceProfilesForRole",
                "iam:AddUserToGroup",
                "iam:RemoveUserFromGroup",
                "iam:GenerateOrganizationsAccessReport",
                "iam:DeleteRolePolicy",
                "iam:ListAttachedUserPolicies",
                "iam:ListAttachedGroupPolicies",
                "iam:CreatePolicyVersion",
                "iam:DeleteLoginProfile",
                "iam:DeleteInstanceProfile",
                "iam:GetInstanceProfile",
                "iam:ListGroupPolicies",
                "iam:PutUserPermissionsBoundary",
                "iam:DeleteUser",
                "iam:DeleteUserPermissionsBoundary",
                "iam:ListUserPolicies",
                "iam:ListInstanceProfiles",
                "iam:TagUser",
                "iam:CreatePolicy",
                "iam:UntagUser",
                "iam:CreateServiceLinkedRole",
                "iam:ListPolicyVersions",
                "iam:AttachGroupPolicy",
                "iam:PutUserPolicy",
                "iam:UpdateRole",
                "iam:GetUser",
                "iam:DeleteGroupPolicy",
                "iam:DeletePolicyVersion",
                "iam:SetDefaultPolicyVersion",
                "iam:ListUserTags"
            ],
            "Resource": [
                "arn:aws:iam::*:policy/*",
                "arn:aws:iam::*:instance-profile/*",
                "arn:aws:iam::*:user/*",
                "arn:aws:iam::*:role/*",
                "arn:aws:iam::*:access-report/*",
                "arn:aws:iam::*:group/*"
            ]
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "iam:GenerateCredentialReport",
                "iam:ListPolicies",
                "iam:GetAccountPasswordPolicy",
                "iam:DeleteAccountPasswordPolicy",
                "iam:ListPoliciesGrantingServiceAccess",
                "iam:ListRoles",
                "iam:SimulateCustomPolicy",
                "iam:UpdateAccountPasswordPolicy",
                "iam:CreateAccountAlias",
                "iam:ListAccountAliases",
                "iam:ListUsers",
                "iam:ListGroups",
                "iam:DeleteAccountAlias",
                "iam:GetAccountAuthorizationDetails"
            ],
            "Resource": "*"
        }
    ]
}   
```

### DynamoDB
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "dynamodb:BatchGetItem",
                "dynamodb:PutItem",
                "dynamodb:UntagResource",
                "dynamodb:DeleteItem",
                "dynamodb:CreateTableReplica",
                "dynamodb:DeleteTableReplica",
                "dynamodb:Query",
                "dynamodb:UpdateItem",
                "dynamodb:DeleteTable",
                "dynamodb:CreateTable",
                "dynamodb:TagResource",
                "dynamodb:DescribeTable",
                "dynamodb:GetItem",
                "dynamodb:UpdateTable",
                "dynamodb:DescribeTableReplicaAutoScaling"
            ],
            "Resource": "arn:aws:dynamodb:*:*:table/*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "dynamodb:ListTables",
                "dynamodb:DescribeReservedCapacity",
                "dynamodb:DescribeLimits",
                "dynamodb:ListStreams"
            ],
            "Resource": "*"
        }
    ]
}
```