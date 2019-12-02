# Terraform + CodePipeline + EKS

Este projeto tem como objetivo demonstrar a automação e a Infraestructure-as-code (IaC), de um projeto proivisionado totalmente na AWS, utilizando seus recursos de forma pratica e explicita. Neste projeto abordaremos o Terraform, armazenando seus arquivos no S3, e provisionando totalmente a infra necessária para que a aplicação execute perfeitamente, além disto, utilizaremos os recursos do CodePipeline e CodeBuild, para fazer a automatização dos builds, teste e deployments de nossa aplicação.

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
> Estes comandos devem ser executados dentro da pasta principal de cada Serviço/InfraEstrutura. No caso acima, será necessário executar este comando na pasta *Terraform/Global*

Ao finalizar a execução de ambos os comandos, será criado um Bucket S3 para armazenar todos os arquivos Tf State, e uma tabela no Dynamo DB para fazer a gestão de cada Locks.

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

### Infra-Estrutura

Apos a criacao de todos o processo de Build automatizado, iremos criar a arquitetura necessaria para que nossa aplicacao execute na infra. Nesta etapa optamos por utilizar o EKS, pela questao da seguranca, praticidade e compatibilidade com os recursos da AWS, alem de nos prover uma rapida escalabilidade e uma alta disponibilidade.

Para isso optamos por criar uma VPC exclusiva para o EKS e seus workers, sendo divididas em 4 Subnets, sendo 2 delas para operar junto com o EKS Cluster Principal e outra para operarmos com seus Node Group. Optamos por utilizar uma VPC com acesso a internet, para facilitar o gerenciamento do Cluster, entretanto e altamente recomendado que seja configurado um Cluster, que tenha 2 Subredes Privadas e 2 SubRedes publicas, para que sejam utilizados de acordo com a necessidade do servico, podendo ser um servico que nao necessite acesso externo ou um servico que necessite de um acesso externo. Por mais que o EKS tenha um rede interna, muitas vezes e necessario que outros servicos dentro da rede tenha acesso a ele e com isso foi criado uma regra de firewall para fazer a gerencia do que pode e nao pode trafegar para o EKS.

Criado o EKS, e necessario que seja criado o Node Group(Workes), para que tenhamos recursos necessario para prover nossa aplicacao. Cada Node Group e necessario que seja selecionados a Instancia EC2 desejada, as subnets que serao utilizadas pelas instancias, e o tamanho desejado de workers, sendo configurado por *desejado*, *maximo*, *minimo*. Feitas todas essas configuracoes seu Node Group estara pronto para ser utilizado, e seu EKS tambem estara pronto para prover aplicacoes.

Neste projeto temos os arquivos TF Files necessarios para criarmos automaticamente todo o EKS, sendo desde a parte do VPC ate o Node Group. Dentro da pasta *Infraestructure/Development* ou *Infraestructure/Production*, existe um arquivo *main.tf* que é responsável por agrupar todos os recursos necessários, junto com os recursos existem alguns valores que podem ser modificados, para criar ambientes diferentes sempre que necessário, esses valores estão descritos dentro da tag __*locals { }*__, pela qual armazena todas as configurações locais deste Tf File, desta forma caso queira mudar algo para sua infraestrutura gerada, recomendo que modifique neste arquivo. Caso deseje modificar o VPC gerado, e necessario modificar apenas o *main.tf* que esta dentro da pasta *Infraestructure/(Development/Production)/vpc*.

Para iniciar o processo de criação dos serviços é necessário executar os seguintes comandos:

```
terraform init  -> Responsável por baixar e preparar todas as dependências do TerraForm.
terraform apply -auto-approve -> Responsável por criar e gerenciar toda a infraestrutura descrita em cada arquivo TF.
```
> Estes comando devem ser executados dentro da pasta principal de cada Serviço/InfraEstrutura. No caso acima, será necessário executar este comando na pasta *Terraform/Serviços/__(Development/Production)__*, de acordo com qual ambiente deseja provisionar.

## AWS

### CodePipeline

Optamos por utilizar o CodePipeline pela praticidade de integracao com todos os recursos da AWS, e facil integracao com o Source de nosso projeto, que esta hospedado no GitHub. Para utilizarmos ele, usamos o WebHook do GitHub para disparar os Build de forma automatizada, sempre que ocorrer algum push no projeto. Junto com ele utilizamos o CodeBuild, para prover todo o Build automatico de nosso projeto.

O CodePipeline e responsavel por gerenciar todo o pipeline de nosso projeto e dessa forma unir todos os outros recursos de desenvolvimento da AWS em uma unica plataforma, facilitando todo o processo de gerencia e analise. Podemos utilizar o CodeCommit, GitHub, S3, etc, como respositorios de codigos, e ao subir algum arquivo o CodePipeline iniciaria o processo de build. Dessa forma e uma ferramenta poderosa, quando se usado nos ambientes da AWS.

Para o processo de build, optamos por utilizar o CodeBuild, pela praticidade na integracao com o CodePipeline e os recursos da AWS. E necessario apenas escrever um arquivo *buildspec.yml* no projeto e definir todos os passos necessarios para o processo de build da aplicacao.
> Este arquivo *buildspec.yml* esta definido no root deste repositorio, por questoes de praticidade. Nas consideracoes finais, tera uma overview de toda organizacao deste repositorio.

#### CodeBuild

Para configuraca do CodeBuild, optamos por configurar uma maquina mais lenta para o ambiente de *development* e uma maquina mais poderosa para o ambiente de *production*, por questoes de custo. E tambem possivel configurar uma rede VPC, para que o CodeBuild tenha acesso a rede interna da AWS, porem optamos por nao configurar, pela nao necessidade de acesso a alguma aplicacao interna.

### EKS

Optamos pela utilizacao do EKS para este projeto, gracas a sua escalabilidade, alta disponibilidade, divisao de responsabilidade e __seguranca__.