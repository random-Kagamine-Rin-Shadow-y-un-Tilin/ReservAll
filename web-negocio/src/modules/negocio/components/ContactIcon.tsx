import { MdLocalPhone } from "react-icons/md";
import { IoLogoTiktok } from "react-icons/io5";
import { TbLetterX } from "react-icons/tb";
import { ImSphere } from "react-icons/im";
import { IoLogoFacebook, IoLogoInstagram, IoLogoWhatsapp } from "react-icons/io";
import { LuLink } from "react-icons/lu";

const icons = {
  facebook: IoLogoFacebook,
  instagram: IoLogoInstagram,
  whatsapp: IoLogoWhatsapp,
  telefono: MdLocalPhone,
  tiktok: IoLogoTiktok,
  x: TbLetterX,
  sitio_web: ImSphere,
} as const;

export function ContactIcon({
  network,
  size = 18,
}: {
  network: string;
  size?: number;
}) {
  const Icon = icons[network as keyof typeof icons] ?? LuLink;
  return <Icon size={size} />;
}
