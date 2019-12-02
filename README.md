# Terraform + CodePipeline + EKS

Este projeto tem como objetivo demonstra a automação e a Infraestructure-as-code (IaC), de um projeto proivisionado totalmente na AWS, utilizando seus recursos de forma pratica e explicita. Neste projeto abordaremos o Terraform, armazenando seus arquivos no S3, e provisionando totalmente a infra necessária para que a aplicação execute perfeitamente, além disto, utilizaremos os recursos do CodePipeline, CodeBuild, para fazer a automatização dos builds, teste e deployments  de nossa aplicação.

Essa aplicação será provisionada a partir de um EKS - Kubernetes Cluster, que será criada pelo nosso arquivo do Terraform. Todos os passos necessários para a execução deste projeto estão descritos abaixo, caso deseje saber mais a fundo sobre cada parte do projeto, no final existirá um Link para cada ReadME responsável.

## TerraForm

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
    |    |- Route53/ -> Responsável por criar zonas para serem utilizadas neste projeto.
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

Após a configuração necessária para o TerraForm acessar a AWS, será necessária a execução de dois comandos TerraForm, sendo eles:

```
terraform init  -> Responsável por baixar e preparar todas as dependências do TerraForm.
terraform apply -auto-approve -> Responsável por criar e gerenciar toda a infraestrutura descrita em cada arquivo TF.
```
> Estes comando devem ser executados dentro da pasta principal de cada Serviço/InfraEstrutura. No caso acima, seria necessário executar este comando na pasta *Terraform/Global*

Ao finalizar a execução de ambos os comandos, será criado um Bucket S3 para armazenar todos os arquivos Tf State, e uma tabela no Dynamo DB para fazer a gestão de cada Locks.
