# Builder image stage
FROM elevacontainerregistry.azurecr.io/dotnet3 as builder
WORKDIR /app

# copy csproj and restore as distinct layers
COPY . ./
RUN dotnet restore

# build and publish output of the app in out dirs
RUN dotnet publish --no-restore -c Release -o out

# Build runtime image
FROM elevacontainerregistry.azurecr.io/aspnet3 as runtime
WORKDIR /app

## Copy output dirs with all dlls and testscripts
COPY --from=builder /app/*out* ./
COPY unit.sh .
COPY integration.sh .

# SSH stage
RUN apt-get update \
        && apt-get install -y --no-install-recommends dialog \
        && apt-get update \
	&& apt-get install -y --no-install-recommends openssh-server \
	&& echo "root:Docker!" | chpasswd 

COPY sshd_config /etc/ssh/
COPY init.sh /usr/local/bin/
RUN chmod u+x /usr/local/bin/init.sh

## Expose port of app and ssh port
EXPOSE 80 2222
## Initilize ssh and app
CMD ["init.sh"]
